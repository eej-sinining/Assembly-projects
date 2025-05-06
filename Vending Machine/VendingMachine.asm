.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\masm32.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\kernel32.lib

;to run? goto Powershell
; & "C:\masm32\bin\ml.exe" /c /coff VendingMachine.asm
; & "C:\masm32\bin\link.exe" /SUBSYSTEM:CONSOLE VendingMachine.obj
; .\VendingMachine

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
    stockPrompt     db "Enter new stock quantity: ", 0
    stockUpdatedMsg db 13,10,"Stock updated successfully!", 13,10, 0
    
    ;Error messages
    invalidInputMsg db 13,10,"Invalid input! Please try again.", 13,10, 0
    invalidCoinMsg  db 13,10,"Invalid amount. Please enter a valid number.", 13,10, 0
    
    ;Exit message
    exitMsg         db 13,10,"Thank you for using StarCircle Vending Machine. Goodbye!", 13,10, 0
    
    ;Product data
    itemNames       db "Coca-Cola",0,"Sprite",0,"Royal",0,"Mountain Dew",0
    itemPrices      dd 30, 25, 20, 20
    itemStock       dd 5, 5, 5, 5
    
    ;Buffers
    inputBuffer     db 32 dup(0)
    numBuffer       db 16 dup(0)
    tempBuffer      db 16 dup(0)

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
        
        ; Get item price
        mov ecx, [itemPrices + ebx*4]
        
        ; Prompt for payment
        invoke StdOut, addr insertCoinsMsg
        invoke StdIn, addr inputBuffer, sizeof inputBuffer
        
        ; Convert payment to number
        invoke atodw, addr inputBuffer
        
        ; Check if payment is sufficient
        .IF (eax < ecx)
            invoke StdOut, addr notEnoughMsg
            jmp purchase_loop
        .ENDIF
        
        ; Payment is enough - save payment amount in edx
        mov edx, eax
        
        ; Calculate change
        mov eax, edx                 ; Get the payment amount back
        sub eax, ecx                 ; Calculate change (payment - price)
        push eax                     ; Save change amount
        
        ; Update stock
        mov edx, ebx
        mov ecx, [itemStock + edx*4]
        dec ecx
        mov [itemStock + edx*4], ecx
        
        ; Dispense item
        invoke StdOut, addr dispenseMsg
        
        ; Give change
        pop eax   ; Restore change amount
        invoke StdOut, addr changeMsg
        invoke dwtoa, eax, addr numBuffer
        invoke StdOut, addr numBuffer
        
        ; Thank you message
        invoke StdOut, addr thankYouMsg
        
        ret
PurchaseMode ENDP

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
        
        ; Prompt for new stock quantity
        invoke StdOut, addr stockPrompt
        invoke StdIn, addr inputBuffer, sizeof inputBuffer
        
        ; Convert input to number
        invoke atodw, addr inputBuffer
        
        ; Update stock
        mov [itemStock + ebx*4], eax
        
        ; Confirm stock update
        invoke StdOut, addr stockUpdatedMsg
        
        jmp admin_loop

AdminMode ENDP


END start