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

    
    totalItems      db "Number of Products in the Inventory: ",0
    totalValue      db "Total Inventory Value: $",0

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

    nameBuffer db 64 dup(0)
    dupMsg db "Duplicate found. Try again.", 0Dh, 0Ah, 0
    activeProductCount dd 0  ; New variable to store active product count


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
get_code:
    ; Get product code
    invoke StdOut, addr promptCode
    invoke StdIn, addr inputBuffer, sizeof inputBuffer

    ; Check for duplicate code
    mov ecx, productCount
    mov esi, offset products
check_code_loop:
    cmp ecx, 0
    je get_name
    push ecx
    push esi
    lea edi, inputBuffer
    mov ecx, 10
    repe cmpsb
    je duplicate
    pop esi
    add esi, 38
    pop ecx
    dec ecx
    jmp check_code_loop

get_name:
    ; Get product name
    invoke StdOut, addr promptName
    invoke StdIn, addr nameBuffer, sizeof nameBuffer

    ; Check for duplicate name
    mov ecx, productCount
    mov esi, offset products
check_name_loop:
    cmp ecx, 0
    je continue_input
    push ecx
    push esi
    lea esi, [esi+10] ; name field
    lea edi, nameBuffer
    mov ecx, 20
    repe cmpsb
    je duplicate
    pop esi
    add esi, 38
    pop ecx
    dec ecx
    jmp check_name_loop

duplicate:
    pop esi  ; Clean up stack from the pushed values
    pop ecx
    invoke StdOut, addr newLine
    invoke StdOut, addr dupMsg
    jmp continue_add

continue_input:
    ; Calculate position in product array
    mov eax, productCount
    mov ebx, 38
    mul ebx
    lea edi, products[eax]

    ; Store code
    mov esi, offset inputBuffer
    mov ecx, 10
    rep movsb

    ; Store name
    mov esi, offset nameBuffer
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

    ; Increment count
    inc productCount

    invoke StdOut, addr addedMsg
    ret
Addp ENDP


;=====
;View function
;=====
Viewp PROC
    ; Reset the active product count
    mov activeProductCount, 0
    
    ; Check if there are products
    cmp productCount, 0
    jne has_products
    invoke StdOut, addr noProducts
    ret
    
has_products:
    ; Start with first product
    mov esi, offset products
    mov ecx, productCount

view_loop:
    ; Save loop counter
    push ecx
    
    ; Get quantity value (offset 30 from product start)
    mov eax, dword ptr [esi+30]
    
    ; Skip if quantity is 0
    cmp eax, 0
    je skip_this_product
    
    ; Increment active product count
    inc activeProductCount
    
    ; Display this product
    invoke StdOut, addr newLine
    
    ; Show code
    invoke StdOut, addr labelCode
    invoke StdOut, esi
    
    ; Show name
    invoke StdOut, addr labelSep
    lea edi, [esi+10]
    invoke StdOut, edi
    
    ; Show quantity
    invoke StdOut, addr labelQty
    invoke dwtoa, eax, addr outputBuffer
    invoke StdOut, addr outputBuffer
    
    ; Show price
    invoke StdOut, addr labelPrice
    mov eax, [esi+34]
    invoke dwtoa, eax, addr outputBuffer
    invoke StdOut, addr outputBuffer
    invoke StdOut, addr newLine
    
skip_this_product:
    ; Move to next product
    add esi, 38
    pop ecx
    dec ecx
    jnz view_loop
    
    ; Display count of active products
    invoke StdOut, addr newLine
    invoke StdOut, addr totalItems
    mov eax, activeProductCount
    invoke dwtoa, eax, addr outputBuffer
    invoke StdOut, addr outputBuffer
    invoke StdOut, addr newLine
    
    ret
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

    ; Loop through products to find the one to update
    mov edx, 0                  ; Product index
    mov ebx, offset products    ; Base address of products array

search_product_loop:
    cmp edx, productCount       ; Check if we've checked all products
    jge product_not_found
    
    ; Compare product code with input (max 10 chars)
    mov esi, ebx                ; esi points to current product
    mov edi, offset inputBuffer ; edi points to input code
    mov ecx, 10                 ; Max 10 characters to compare
    push edx
    push ebx
    
compare_loop:
    mov al, [esi]
    mov dl, [edi]
    cmp al, dl
    jne codes_not_equal
    cmp al, 0
    je codes_equal
    inc esi
    inc edi
    dec ecx
    jnz compare_loop
    
codes_equal:
    pop ebx
    pop edx
    jmp found_product_to_update
    
codes_not_equal:
    pop ebx
    pop edx
    add ebx, 38                 ; Move to next product
    inc edx
    jmp search_product_loop
    
product_not_found:
    invoke StdOut, addr notFoundMsg
    ret
    
found_product_to_update:
    ; ebx points to the product to update
    
    ; Skip code (first 10 bytes)
    add ebx, 10
    
    ; Update name
    invoke StdOut, addr promptName
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    mov edi, ebx                ; Destination for the name
    mov esi, offset inputBuffer ; Source of the name
    mov ecx, 20                 ; Copy up to 20 bytes
    rep movsb
    
    ; Update quantity (now at quantity field, which is at offset 30 from start of product)
    invoke StdOut, addr promptQty
input_qty:
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    call ValidateNumericInput
    invoke atodw, addr inputBuffer
    ; Fix: Correct offset calculation for quantity (30 - 10 = 20)
    mov [ebx+20], eax           ; Store at qty position
    
    ; Update price
    invoke StdOut, addr promptPrice
input_price:
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    call ValidateNumericInput
    invoke atodw, addr inputBuffer
    ; Fix: Correct offset calculation for price (34 - 10 = 24)
    mov [ebx+24], eax           ; Store at price position

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
    invoke StdOut, addr promptQty
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    jmp validate_loop  ; Ask again until correct
ValidateNumericInput ENDP


;=====
;Delete function
;=====
Deletep PROC
    ; Check if there are products
    cmp productCount, 0
    jne delete_continue
    invoke StdOut, addr noProducts
    ret
    
delete_continue:
    ; Get product code to delete
    invoke StdOut, addr deletePrompt
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    
    ; Loop through products to find the one to delete
    mov edx, 0                  ; Product index
    mov ebx, offset products    ; Base address of products array

delete_search_product_loop:
    cmp edx, productCount       ; Check if we've checked all products
    jge delete_product_not_found
    
    ; Compare product code with input (max 10 chars)
    mov esi, ebx                ; esi points to current product
    mov edi, offset inputBuffer ; edi points to input code
    mov ecx, 10                 ; Max 10 characters to compare
    push edx
    push ebx
    
delete_compare_loop:
    mov al, [esi]
    mov dl, [edi]
    cmp al, dl
    jne delete_codes_not_equal
    cmp al, 0
    je delete_codes_equal
    inc esi
    inc edi
    dec ecx
    jnz delete_compare_loop
    
delete_codes_equal:
    pop ebx
    pop edx
    jmp delete_found_product
    
delete_codes_not_equal:
    pop ebx
    pop edx
    add ebx, 38                 ; Move to next product
    inc edx
    jmp delete_search_product_loop
    
delete_product_not_found:
    invoke StdOut, addr notFoundMsg
    ret
    
delete_found_product:
    ; ebx points to the product to delete
    
    ; Get position of last product
    mov eax, productCount
    dec eax
    mov ecx, 38
    mul ecx
    lea edi, products[eax]  ; edi points to last product
    
    ; Check if this is the last product
    cmp ebx, edi
    je just_decrement
    
    ; Copy last product to this position
    mov esi, edi
    mov edi, ebx
    mov ecx, 38
    rep movsb
    
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