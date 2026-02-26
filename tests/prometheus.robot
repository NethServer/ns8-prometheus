*** Settings ***
Library    SSHLibrary
Resource    api.resource

*** Variables ***
${IMAGE_URL}             ghcr.io/nethserver/prometheus:latest
${SCENARIO}              install

*** Keywords ***
Retry test
    [Arguments]    ${keyword}
    Wait Until Keyword Succeeds    60 seconds    1 second    ${keyword}

Backend URL is reachable
    ${rc} =    Execute Command    curl -f ${backend_url}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0


*** Test Cases ***
Add module for ${SCENARIO} scenario
    IF    r'${SCENARIO}' == 'update'
        Set Local Variable  ${iurl}  prometheus
    ELSE
        Set Local Variable  ${iurl}  ${IMAGE_URL}
    END
    ${output}  ${rc} =    Execute Command    add-module ${iurl} 1
    ...    return_rc=True
    Should Be Equal As Integers    ${rc}  0
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

Check if prometheus is removed correctly
    ${rc} =    Execute Command    remove-module --no-preserve ${module_id}
    ...    return_rc=True  return_stdout=False
    Should Be Equal As Integers    ${rc}  0
