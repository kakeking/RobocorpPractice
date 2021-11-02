*** Settings ***
Documentation    Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library          RPA.Browser.Selenium
Library          RPA.HTTP
Library          RPA.Excel.Files
Library          RPA.Tables
Library          RPA.PDF
Library          Screenshot
Library          RPA.Archive
Library          RPA.Dialogs
*** Variables ***
${output_folder}     ${CURDIR}${/}output
${receipt_folder}    ${CURDIR}${/}output${/}receipts

*** Keywords ***
Open the robot order website
    Open Available Browser   https://robotsparebinindustries.com/#/robot-order

*** Keywords ***
Get orders
    Add text input    url    label=Orders CSV Url
    ${response}=    Run dialog
    # https://robotsparebinindustries.com/orders.csv
    Download     ${response.url}   overwrite=True
    ${orders}=  Read table from CSV    orders.csv
    [Return]    ${orders}

Close the annoying modal
      Click Button    xpath://*[text()="OK"]
Fill the form
    [Arguments]    ${row}
    Select From List By Value    name:head    ${row}[Head]
    Click Element    //label[./input[@value=${row}[Body]]]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    name:address    ${row}[Address]

Preview the robot
    Click Button When Visible    id:preview

Submit the order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file 
    [Arguments]    ${Order number}
    ${receipt_html} =     Get Element Attribute    id:receipt    outerHTML
    ${pdf}    Set Variable     ${receipt_folder}${/}${Order number}.pdf
    Html To Pdf    ${receipt_html}    ${pdf}
    [Return]     ${pdf}

Go to order another robot
    Click Button When Visible  id:order-another

Take a screenshot of the robot 
    [Arguments]    ${Order number}
    ${Screen_shot}    Set Variable    ${output_folder}${/}${Order number}.jpg
    ${Screen_shot}=    Take Screenshot     ${Screen_shot}
    [Return]    ${Screen_shot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf    ${pdf}

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip    ${receipt_folder}    ${zip_file_name}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Log    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds   10X     3S    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
