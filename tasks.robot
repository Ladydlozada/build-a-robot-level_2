*** Settings ***
Documentation     Certificate level II: Build a robot
Library           RPA.Browser    auto_close=${FALSE}
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocloud.Secrets
Library           RPA.core.notebook
Library           OperatingSystem
Library           RPA.Robocloud.Secrets

*** Tasks ***
Order Processing Bot
    Intializing
    Download the csv file
    Read the order file
    Open the website
    Loop CSV
    Close Down
    #[Teardown]    Close Browser

*** Variables ***
${Archivo_CSV}=    orders.csv
${Descargas}=     ${CURDIR}${/}Descargas
${ReciboPDF}=     ${CURDIR}${/}RecibosPDF
${Directorio}=    ${Descargas}${/}${Archivo_CSV}

*** Keywords ***
 Intializing
    Remove File    ${Archivo_CSV}
    Create Directory    ${Descargas}
    Create Directory    ${ReciboPDF}

*** Keywords ***
Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    ${Directorio}    verify=True    overwrite=True

*** Keywords ***
Read the order file
    ${data}=    Read Table From Csv    ${Directorio}    header=True
    Return From Keyword    ${data}

*** Keywords ***
Open the website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    Wait Until Page Contains Element    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]

*** Keywords ***
Order
    Click Element When Visible    id:order
    Wait Until Element Is Visible    id:receipt

*** Keywords ***
Loop CSV
    ${orders}=    Read Table From Csv    ${Directorio}
    FOR    ${order}    IN    @{orders}
        Select From List By Value    id:head    ${order}[Head]
        Click Element When Visible    id:id-body-${order}[Body]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[4]/input    ${order}[Address]
        Click Button    //button[@id="preview"]
        Wait Until Page Contains Element    //div[@id="robot-preview-image"]
        Sleep    3 seconds
        Click Button    //button[@id="order"]
        Sleep    3 seconds
        ${reciept_data}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
        Html To Pdf    ${reciept_data}    ${ReciboPDF}${/}${order}[Order number].pdf
        Screenshot    //div[@id="robot-preview-image"]    ${Descargas}${/}${order}[Order number].png
        Add Watermark Image To Pdf    ${Descargas}${/}${order}[Order number].png    ${ReciboPDF}${/}${order}[Order number].pdf    ${ReciboPDF}${/}${order}[Order number].pdf
        Click Element When Visible    id:order-another
        Wait Until Keyword Succeeds    1 min    5 sec    Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    END
    Archive Folder With Zip    ${ReciboPDF}    ${OUTPUT_DIR}${/}ReciboPDF.zip

*** Keywords ***
Close Down
    Remove Directory    Descargas    True
    Remove Directory    RecibosPDF    True
