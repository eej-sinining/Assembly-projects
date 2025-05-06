.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\masm32.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\kernel32.lib

.DATA

    ;==================== to run =============================
    ; & "C:\masm32\bin\ml.exe" /c /coff brymi.asm
    ; & "C:\masm32\bin\link.exe" /SUBSYSTEM:CONSOLE brymi.obj
    ; .\brymi.exe
    ;=========================================================

    menuTitle   db "===| Mini Inventory System |===",13,10
                db "1. Add Product",13,10
                db "2. View Products",13,10
                db "3. Update Quantity",13,10
                db "4. Delete Product",13,10
                db "5. Exit",13,10,0

    newLine         db 13,10,0
    promptChoice    db "Enter your choice:",0
    promptCode      db "Enter product code:",0
    promptName      db "Enter product name:",0
    promptQty       db "Enter quantity:",0
    promptPrice     db "Enter price:",0
    promptNewQty    db "Enter new quantity:",0

    updatePrompt    db "Enter product code to update:", 0
    deletePrompt    db "Enter product code to delete:", 0
    invalidInputMsg db "Invalid input! Please enter a number.", 13, 10, 0


    addedMsg        db "Product added successfully!",13,10,0
    updatedMsg      db "Product updated!",13,10,0
    deletedMsg      db "Product deleted.",13,10,0
    notFoundMsg     db "Product not found.",13,10,0
    inventoryFull   db "Inventory full!",13,10,0
    invalidChoice   db "Invalid choice!",13,10,0
    noProducts      db "No products in inventory.",13,10,0

    totalLabel      db "Total Inventory Value: ",0

    inputBuffer     db 64 DUP(0)
    outputBuffer    db 64 DUP(0)
    
    ; Product structure: code(10), name(20), qty(4), price(4)
    MAX_PRODUCTS = 100
    products       db MAX_PRODUCTS * 38 DUP(0)  ; Each product is 38 bytes
    productCount   dd 0

    labelCode      db "code: ", 0
    labelSep       db " | name:", 0
    labelQty       db " | qty: ", 0
    labelPrice     db " | price: ", 0

.CODE
start:
mainloop:
    invoke StdOut,addr newLine
    invoke StdOut, addr menuTitle
    invoke StdOut, addr promptChoice
    invoke StdIn, addr inputBuffer, sizeof inputBuffer

    mov al, byte ptr [inputBuffer]

    .IF al == '1'
        call Addp
    .ELSEIF al == '2'
        call Viewp
    .ELSEIF al == '3'
        call Updatep
    .ELSEIF al == '4'
        call Deletep
    .ELSEIF al == '5'
        call Exitp
    .ELSE
        invoke StdOut, addr invalidChoice
    .ENDIF

    jmp mainloop
exit_program:
    invoke ExitProcess, 0
    

;=====
;Add function
;=====
Addp PROC
    ; Check if inventory is full
    mov eax, productCount
    cmp eax, MAX_PRODUCTS
    jl continue_add
    invoke StdOut, addr inventoryFull
    ret
    
continue_add:
    ; Get product code
    invoke StdOut, addr promptCode
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    
    ; Calculate product position (eax = productCount * 38)
    mov eax, productCount
    mov ebx, 38
    mul ebx
    lea edi, products[eax]
    
    ; Copy code (first 10 bytes)
    mov esi, offset inputBuffer
    mov ecx, 10
    rep movsb
    
    ; Get product name
    invoke StdOut, addr promptName
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    
    ; Copy name (next 20 bytes)
    mov esi, offset inputBuffer
    mov ecx, 20
    rep movsb
    
    ; Get quantity
    invoke StdOut, addr promptQty
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    invoke atodw, addr inputBuffer
    mov [edi], eax
    add edi, 4
    
    ; Get price
    invoke StdOut, addr promptPrice
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    invoke atodw, addr inputBuffer
    mov [edi], eax
    
    ; Increment product count
    inc productCount
    
    invoke StdOut, addr addedMsg
    ret
Addp ENDP

;=====
;View function
;=====
Viewp PROC
    ; Check if there are products
    cmp productCount, 0
    jne view_products
    invoke StdOut, addr noProducts
    ret
    
view_products:
    mov esi, offset products
    mov ecx, productCount
    mov ebx, 0  ; Total value accumulator
    
view_loop:
    push ecx

    ; Newline before each product
    invoke StdOut, addr newLine

    ; Show "code: "
    invoke StdOut, addr labelCode
    invoke StdOut, esi ; product code (10 bytes)

    ; Show " | "
    invoke StdOut, addr labelSep

    ; Show product name
    add esi, 10
    invoke StdOut, esi ; name (20 bytes)

    ; Show " | qty: "
    invoke StdOut, addr labelQty
    add esi, 20
    mov eax, [esi] ; quantity
    invoke dwtoa, eax, addr outputBuffer
    invoke StdOut, addr outputBuffer

    ; Show " | price: "
    invoke StdOut, addr labelPrice
    add esi, 4
    mov eax, [esi] ; price
    invoke dwtoa, eax, addr outputBuffer
    invoke StdOut, addr outputBuffer
    invoke StdOut, addr newLine

    ; Calculate total value
    mov edx, [esi-4]  ; quantity
    imul edx, eax     ; quantity * price
    add ebx, edx

    jmp mainloop


Viewp ENDP

;=====
;Update function
;=====
Updatep PROC
    ; Check if there are products
    cmp productCount, 0
    jne continue_update
    invoke StdOut, addr noProducts
    ret

continue_update:
    ; Get product code to update
    invoke StdOut, addr updatePrompt
    invoke StdIn, addr inputBuffer, sizeof inputBuffer

    mov esi, offset products
    mov ecx, productCount
    mov edi, offset inputBuffer
    mov edx, 0

search_update_loop:
    push ecx
    push esi

    mov edi, offset inputBuffer  ; always reset EDI to input buffer
    mov ecx, 10
    repe cmpsb
    je found_update

    pop esi
    add esi, 38   ; Move to next product
    pop ecx
    loop search_update_loop


found_update:
    sub esi, 10      ; go back to start of matched product
    mov edi, esi     ; backup the full product entry address

    ; Move to name (10 bytes offset)
    add edi, 10
    invoke StdOut, addr promptName
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    mov ecx, 20
    mov esi, offset inputBuffer
    rep movsb

    ; Move to quantity (10 + 20 = 30)
    invoke StdOut, addr promptQty
input_qty:
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    call ValidateNumericInput
    invoke atodw, addr inputBuffer
    mov [edi], eax   ; edi already points to qty
    add edi, 4       ; move to price

    ; Update price
    invoke StdOut, addr promptPrice
input_price:
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    call ValidateNumericInput
    invoke atodw, addr inputBuffer
    mov [edi], eax

    invoke StdOut, addr updatedMsg
    ret

Updatep ENDP
ValidateNumericInput PROC
    mov esi, offset inputBuffer
validate_loop:
    mov al, [esi]
    cmp al, 0
    je valid_input
    cmp al, '0'
    jb invalid_input
    cmp al, '9'
    ja invalid_input
    inc esi
    jmp validate_loop

valid_input:
    ret

invalid_input:
    invoke StdOut, addr invalidInputMsg
    jmp validate_loop  ; Ask again until correct
ValidateNumericInput ENDp


;=====
;delete function
;=====
Deletep PROC
    ; Check if there are products
    cmp productCount, 0
    jne delete_continue
    invoke StdOut, addr noProducts
    ret
    
delete_continue:
    ; Get product code to delete
    invoke StdOut, addr promptCode
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    
    ; Search for product
    mov esi, offset products
    mov ecx, productCount
    
delete_search_loop:
    push ecx
    mov edi, offset inputBuffer
    mov ecx, 10
    repe cmpsb
    je found_product_to_delete
    
    ; Not this product, move to next
    add esi, 38 - 10  ; 10 already advanced by cmpsb
    pop ecx
    loop delete_search_loop
    
    ; Product not found
    invoke StdOut, addr notFoundMsg
    ret
    
found_product_to_delete:
    ; Calculate position of last product
    mov eax, productCount
    dec eax
    mov ebx, 38
    mul ebx
    lea edi, products[eax]
    
    ; Check if this is the last product
    cmp esi, edi
    je just_decrement
    
    ; Copy last product to this position
    push esi
    mov ecx, 38
    rep movsb
    pop esi
    
just_decrement:
    ; Decrement product count
    dec productCount
    invoke StdOut, addr deletedMsg
    ret
Deletep ENDP

;=====
;Exit function
;=====
Exitp PROC
    jmp exit_program
Exitp ENDP

end start