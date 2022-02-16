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
Pasos a ejecutar
    Inicio (Si existe Csv, lo borro Y Creo Las Carpetas en el Directorio Raiz)
    Descargo el Archivo CSV y lo guardo en la Carpeta Descargas, si llega a existir lo sobreescribo
    Abro el Portal, lo maximizo, le doy tiempo y luego presiono el boton OK
    Hago el Loop al CSV
    Elimino las 2 Carpetas creadas, para que no afecte las prox corridas
    [Teardown]    Close Browser

*** Variables ***
${Archivo_CSV}=    orders.csv
${Descargas}=     ${CURDIR}${/}Descargas
${ReciboPDF}=     ${CURDIR}${/}RecibosPDF
${Directorio}=    ${Descargas}${/}${Archivo_CSV}

*** Keywords ***
Inicio (Si existe Csv, lo borro Y Creo Las Carpetas en el Directorio Raiz)
    Remove File    ${Archivo_CSV}
    Create Directory    ${Descargas}
    Create Directory    ${ReciboPDF}

*** Keywords ***
Descargo el Archivo CSV y lo guardo en la Carpeta Descargas, si llega a existir lo sobreescribo
    Download    https://robotsparebinindustries.com/orders.csv    ${Directorio}    verify=True    overwrite=True

*** Keywords ***
Abro el Portal, lo maximizo, le doy tiempo y luego presiono el boton OK
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
    Wait Until Page Contains Element    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]

*** Keywords ***
Order
    Click Element When Visible    id:order
    Wait Until Element Is Visible    id:receipt

*** Keywords ***
Hago el Loop al CSV
    ${orders}=    Read Table From Csv    ${Directorio}
    FOR    ${order}    IN    @{orders}
        Select From List By Value    id:head    ${order}[Head]
        Click Element When Visible    id:id-body-${order}[Body]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
        Input Text    xpath://*[@id="root"]/div/div[1]/div/div[1]/form/div[4]/input    ${order}[Address]
        Click Button    //button[@id="preview"]
        Wait Until Keyword Succeeds    10x    1 sec    Order
        ${Datos_Recibidos}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
        Html To Pdf    ${Datos_Recibidos}    ${ReciboPDF}${/}${order}[Order number].pdf
        Screenshot    //div[@id="robot-preview-image"]    ${Descargas}${/}${order}[Order number].png
        Add Watermark Image To Pdf    ${Descargas}${/}${order}[Order number].png    ${ReciboPDF}${/}${order}[Order number].pdf    ${ReciboPDF}${/}${order}[Order number].pdf
        Click Element When Visible    id:order-another
        Wait Until Keyword Succeeds    1 min    5 sec    Click Button When Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    END
    Archive Folder With Zip    ${ReciboPDF}    ${OUTPUT_DIR}${/}ReciboPDF.zip

*** Keywords ***
Elimino las 2 Carpetas creadas, para que no afecte las prox corridas
    Remove Directory    Descargas    True
    Remove Directory    RecibosPDF    True
