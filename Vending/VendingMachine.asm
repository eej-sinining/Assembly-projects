.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\masm32.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\kernel32.lib

;============= to run? goto Powershell ==============
; & "C:\masm32\bin\ml.exe" /c /coff VendingMachine.asm
; & "C:\masm32\bin\link.exe" /SUBSYSTEM:CONSOLE VendingMachine.obj
; .\VendingMachine.exe
;====================================================

.DATA
    ;Main menu Msgs
    titleMsg        db "====== StarCircle Vending Machine ======", 0
    mainMenuMsg    db 13,10,"[A] Purchase Items", 13,10,
                            "[B] Admin Mode (Update Stock)", 13,10,
                            "[C] Exit", 13,10, 13,10,"Enter choice: ", 0
    
    ;Displays
    itemListTitle   db 13,10,"======== Available Products ========", 13,10, 0
    item1Msg        db "[1] Coca-Cola    - 30 PHP (Stock: ", 0
    item2Msg        db "[2] Sprite       - 25 PHP (Stock: ", 0
    item3Msg        db "[3] Royal        - 20 PHP (Stock: ", 0
    item4Msg        db "[4] Mountain Dew - 20 PHP (Stock: ", 0
    closeParen      db ")", 13, 10, 0
    selectPrompt    db 13,10,"Choose item (1-4) or type '0' to return: ", 0
    bottomdash      db 13,10,"====================================",0
    newLine         db 13,10,0

    ;receipt
    receiptMsg      db 13,10,"======== RECEIPT ========", 13,10, 0
    brandTitle      db "StarCircle Vending Machine", 13,10, 0
    itemTitle       db "Item: ", 0
    priceTitle      db "Price: PHP ", 0
    coinInsertedTitle db "Coin Inserted: PHP ", 0
    changeTitle     db "Change: PHP ", 0
    totalTitle      db "Total: PHP ", 0
    receiptEnd      db 13,10,"========================", 13,10, 0
    
    ;Items
    colaMsg         db 13,10,"You selected Coca-Cola!", 13,10, 0
    spriteMsg       db 13,10,"You selected Sprite!", 13,10, 0
    royalMsg        db 13,10,"You selected Royal!", 13,10, 0
    mountainDewMsg  db 13,10,"You selected Mountain Dew!", 13,10, 0
    
    ;Transactions
    insertCoinsMsg  db "Please insert coins (PHP): ", 0
    notEnoughMsg    db 13,10,"Not enough money! You need more PHP.", 13,10, 0
    dispenseMsg     db 13,10,"Dispensing your drink... Enjoy!", 13,10, 0
    changeMsg       db 13,10,"Your change: PHP ", 0
    thankYouMsg     db 13,10,"Thank you for your purchase!", 13,10, 0
    outOfStockMsg   db 13,10,"Sorry, this item is out of stock!", 13,10, 0
    
    ;Admin
    adminModeMsg    db 13,10,"====== ADMIN MODE ======", 13,10, 0
    adminPrompt     db 13,10,"Select item to restock (1-4) or '0' to return: ", 0
    stockPrompt     db "Enter quantity to add to stock: ", 0
    stockUpdatedMsg db 13,10,"Stock updated successfully!", 13,10, 0
    
    ;Error messages
    invalidInputMsg db 13,10,"Invalid input! Please try again.", 13,10, 0
    invalidCoinMsg  db 13,10,"Invalid amount. Please enter a valid number.", 13,10, 0
    
    ;Exit message
    exitMsg         db 13,10,"Thank you for using StarCircle Vending Machine. Goodbye!", 13,10, 0
    
    ;Product data
    itemNames       db "Coca-Cola",0
                    db "Sprite",0
                    db "Royal",0
                    db "Mountain Dew",0
    itemPrices      dd 30, 25, 20, 20
    itemStock       dd 5, 5, 5, 5
    itemReStock     dd 0
    
    ;Buffers
    inputBuffer     db 32 dup(0)
    numBuffer       db 16 dup(0)
    tempBuffer      db 16 dup(0)
    nameBuffer      db 32 dup(0)
    
    paymentAmount   dd 0
    itemPrice       dd 0
    changeAmount    dd 0
    currentStock    dd 0
    addedStock      dd 0
    selectedItem    dd 0

.CODE
start:
    main_loop:
        ;Display main menu
        invoke StdOut, addr titleMsg
        invoke StdOut, addr mainMenuMsg
        invoke StdIn, addr inputBuffer, sizeof inputBuffer
        
        mov al, byte ptr [inputBuffer]
        
        .IF (al == 'A' || al == 'a')
            call PurchaseMode
        .ELSEIF (al == 'B' || al == 'b')
            call AdminMode
        .ELSEIF (al == 'C' || al == 'c')
            invoke StdOut, addr exitMsg
            jmp exit_program
        .ELSE
            invoke StdOut, addr invalidInputMsg
        .ENDIF
        
        jmp main_loop
    
    exit_program:
        invoke ExitProcess, 0

;===================
;Purchase Procedures
;===================
PurchaseMode PROC
    purchase_loop:
        ; Display available items with current stock
        invoke StdOut, addr itemListTitle
        
        ; Display Item 1 (Coca-Cola)
        invoke StdOut, addr item1Msg
        mov eax, [itemStock]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Display Item 2 (Sprite)
        invoke StdOut, addr item2Msg
        mov eax, [itemStock+4]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Display Item 3 (Royal)
        invoke StdOut, addr item3Msg
        mov eax, [itemStock+8]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Display Item 4 (Mountain Dew)
        invoke StdOut, addr item4Msg
        mov eax, [itemStock+12]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Prompt for item selection
        invoke StdOut, addr bottomdash
        invoke StdOut, addr selectPrompt
        invoke StdIn, addr inputBuffer, sizeof inputBuffer
        
        ; Convert input to number
        invoke atodw, addr inputBuffer
        
        ; Check if user wants to return to main menu
        .IF (eax == 0)
            ret
        .ENDIF
        
        ; Validate item selection (1-4)
        .IF (eax < 1 || eax > 4)
            invoke StdOut, addr invalidInputMsg
            jmp purchase_loop
        .ENDIF
        
        ; Store selected item index
        mov ebx, eax
        dec ebx  ; Convert to 0-based index
        mov [selectedItem], ebx  ; Save selected item for later use in receipt
        
        ; Check if item is in stock
        mov ecx, [itemStock + ebx*4]
        .IF (ecx <= 0)
            invoke StdOut, addr outOfStockMsg
            jmp purchase_loop
        .ENDIF
        
        ; Display item selection message
        .IF (ebx == 0)
            invoke StdOut, addr colaMsg
        .ELSEIF (ebx == 1)
            invoke StdOut, addr spriteMsg
        .ELSEIF (ebx == 2)
            invoke StdOut, addr royalMsg
        .ELSEIF (ebx == 3)
            invoke StdOut, addr mountainDewMsg
        .ENDIF
        
        ; Get and store item price
        mov ecx, [itemPrices + ebx*4]
        mov [itemPrice], ecx
        
        ; Prompt for payment
        invoke StdOut, addr insertCoinsMsg
        invoke StdIn, addr inputBuffer, sizeof inputBuffer
        
        ; Convert payment to number
        invoke atodw, addr inputBuffer
        mov [paymentAmount], eax
        
        ; Check if payment is sufficient
        .IF (eax < [itemPrice])
            invoke StdOut, addr notEnoughMsg
            jmp purchase_loop
        .ENDIF
        
        ; Update stock
        mov ecx, [itemStock + ebx*4]
        dec ecx
        mov [itemStock + ebx*4], ecx
        
        ; Dispense item
        invoke StdOut, addr dispenseMsg
        
        ; Calculate change
        mov eax, [paymentAmount]
        sub eax, [itemPrice]
        mov [changeAmount], eax
        
        ; Display change
        ; invoke StdOut, addr changeMsg
        ; mov eax, [changeAmount]
        ; invoke dwtoa, eax, addr numBuffer
        ; invoke StdOut, addr numBuffer
        
        ; Print receipt
        call PrintReceipt
        
        ; Thank you message
        invoke StdOut, addr thankYouMsg
        invoke StdOut, addr newLine
        
        ret
PurchaseMode ENDP

;===================
;Print Receipt
;===================
PrintReceipt PROC
    ; Display receipt header
    invoke StdOut, addr newLine
    invoke StdOut, addr receiptMsg
    invoke StdOut, addr newLine
    
    ; Get item name based on selected item
    mov ebx, [selectedItem]
    mov esi, 0    ; String index counter
    mov edi, 0    ; Item counter
    
    ; Navigate to the correct item name in the string table
    find_name_loop:
        .IF (edi == ebx)
            lea edi, [itemNames + esi]  ; Load address of the item name
            invoke StdOut, addr itemTitle
            invoke StdOut, edi
            invoke StdOut, addr newLine
            jmp name_found
        .ENDIF
        
        ; Skip to the next string (find null terminator)
        .WHILE (byte ptr [itemNames + esi] != 0)
            inc esi
        .ENDW
        inc esi    ; Skip the null terminator
        inc edi    ; Next item
        jmp find_name_loop
        
    name_found:
    
    ; Display price
    invoke StdOut, addr priceTitle
    mov eax, [itemPrice]
    invoke dwtoa, eax, addr numBuffer
    invoke StdOut, addr numBuffer
    invoke StdOut, addr newLine
    
    ; Display coin inserted
    invoke StdOut, addr coinInsertedTitle
    mov eax, [paymentAmount]
    invoke dwtoa, eax, addr numBuffer
    invoke StdOut, addr numBuffer
    invoke StdOut, addr newLine
    
    ; Display change
    invoke StdOut, addr changeTitle
    mov eax, [changeAmount]
    invoke dwtoa, eax, addr numBuffer
    invoke StdOut, addr numBuffer
    invoke StdOut, addr newLine
    
    ; Display total (which is the item price)
    invoke StdOut, addr totalTitle
    mov eax, [itemPrice]
    invoke dwtoa, eax, addr numBuffer
    invoke StdOut, addr numBuffer
    invoke StdOut, addr newLine
    
    ; End receipt
    invoke StdOut, addr receiptEnd
    
    ret
PrintReceipt ENDP

;================
;Admin Procedures
;================
AdminMode PROC
    ; Display admin menu
    invoke StdOut, addr adminModeMsg
    
    admin_loop:
        ; Display current stock
        invoke StdOut, addr itemListTitle
        
        ; Display Item 1 (Coca-Cola)
        invoke StdOut, addr item1Msg
        mov eax, [itemStock]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Display Item 2 (Sprite)
        invoke StdOut, addr item2Msg
        mov eax, [itemStock+4]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Display Item 3 (Royal)
        invoke StdOut, addr item3Msg
        mov eax, [itemStock+8]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Display Item 4 (Mountain Dew)
        invoke StdOut, addr item4Msg
        mov eax, [itemStock+12]
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr closeParen
        
        ; Prompt for item selection
        invoke StdOut, addr adminPrompt
        invoke StdIn, addr inputBuffer, sizeof inputBuffer
        
        ; Convert input to number
        invoke atodw, addr inputBuffer
        
        ; Check if admin wants to return to main menu
        .IF (eax == 0)
            ret
        .ENDIF
        
        ; Validate item selection (1-4)
        .IF (eax < 1 || eax > 4)
            invoke StdOut, addr invalidInputMsg
            jmp admin_loop
        .ENDIF
        
        ; Store selected item index
        mov ebx, eax
        dec ebx  ; Convert to 0-based index
        
        ; Get current stock and display it
        mov eax, [itemStock + ebx*4]
        mov [currentStock], eax
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        invoke StdOut, addr newLine
        
        ; Prompt for additional stock quantity
        invoke StdOut, addr stockPrompt
        invoke StdIn, addr inputBuffer, sizeof inputBuffer
        
        ; Convert input to number
        invoke atodw, addr inputBuffer
        mov [addedStock], eax
        
        mov eax, [currentStock]
        add eax, [addedStock]
        mov [itemStock + ebx*4], eax
        
        ; Display new stock quantity
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        
        ; Confirm stock update
        invoke StdOut, addr stockUpdatedMsg
        
        jmp admin_loop

AdminMode ENDP

END start