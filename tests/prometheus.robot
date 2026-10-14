*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${IMAGE_URL}             ghcr.io/nethserver/prometheus:latest
${SCENARIO}              install
${CLUSTER_USER}          admin
${CLUSTER_PASSWORD}      Nethesis,1234
${module_id}    ${EMPTY}
${backend_url}  ${EMPTY}

*** Keywords ***
Retry test
    [Arguments]    ${keyword}
    Wait Until Keyword Succeeds    60 seconds    1 second    ${keyword}

Backend URL is reachable
    ${rc} =    Execute Command    curl -f ${backend_url}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0

Login to cluster-admin
    New Page    https://${NODE_ADDR}/cluster-admin/
    Fill Text    text="Username"    ${CLUSTER_USER}
    Click    button >> text="Continue"
    Fill Text    text="Password"    ${CLUSTER_PASSWORD}
    Click    button >> text="Log in"
    Wait For Elements State    css=#main-content    visible    timeout=10s

Screenshot page
    [Arguments]    ${route}    ${title}    ${index}
    Go To    https://${NODE_ADDR}/cluster-admin/#/apps/${module_id}${route}
    Wait For Elements State    iframe >>> h2 >> text="${title}"    visible    timeout=10s
    # The page fills itself from several tasks: let them land
    Sleep    5s
    Take Screenshot    filename=${OUTPUT DIR}/browser/screenshot/${index}._${title}.png

Add module
    [Arguments]    ${image}
    ${output}  ${rc} =    Execute Command    add-module ${image} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
    RETURN    ${output}

*** Test Cases ***
Add module for ${SCENARIO} scenario
    # prometheus is published in NethForge, which a new node has disabled
    IF    r'${SCENARIO}' == 'update'
        Run task    cluster/alter-repository    {"name":"nethforge","status":true}
        ${output} =    Wait Until Keyword Succeeds    5 times    10 seconds    Add module    prometheus
    ELSE
        ${output} =    Add module    ${IMAGE_URL}
    END
    &{output} =    Evaluate    ${output}
    Set Suite Variable    ${module_id}    ${output.module_id}

Configure module
    # Assuming the test is running on a single node cluster
    ${response} =    Run task     module/traefik1/get-route    {"instance":"${module_id}"}
    Set Suite Variable    ${backend_url}    ${response['url']}

Update module
    Retry test    Backend URL is reachable
    Log  Scenario ${SCENARIO} with ${IMAGE_URL}  console=${True}
    IF    r'${SCENARIO}' == 'update'
        ${out}  ${rc} =  Execute Command  api-cli run update-module --data '{"force":true,"module_url":"${IMAGE_URL}","instances":["${module_id}"]}'  return_rc=${True}
        Should Be Equal As Integers  ${rc}  0  action update-module ${IMAGE_URL} failed
    END

Check if prometheus works as expected
    Retry test    Backend URL is reachable

Verify prometheus frontend title
    ${output} =    Execute Command    curl -L -s ${backend_url}
    Should Contain    ${output}    <title>Prometheus

Take screenshots of the module pages
    [Documentation]    Capture what cluster-admin shows for Prometheus.
    ...                Tagged ui: skipped unless RUN_UI_TESTS is true, since it needs a browser.
    [Tags]    ui
    Import Library    Browser
    New Browser    chromium    headless=True
    New Context    ignoreHTTPSErrors=True    viewport={'width': 1280, 'height': 900}
    Login to cluster-admin
    Screenshot page    ${EMPTY}          Status    1
    Screenshot page    ?page=about       About     2
    Close Browser

Check if prometheus is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
