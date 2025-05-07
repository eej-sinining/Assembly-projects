.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc
include \masm32\include\user32.inc     ; Added this include

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib
includelib \masm32\lib\user32.lib      ; Added this library

.data
    ;==================== to run =============================
    ; & "C:\masm32\bin\ml.exe" /c /coff SwiftLoanSystem.asm
    ; & "C:\masm32\bin\link.exe" /SUBSYSTEM:CONSOLE SwiftLoanSystem.obj
    ; .\SwiftLoanSystem.exe
    ;=========================================================
MAX_LOANS    EQU 10

; Strings for output
szName           db "Enter Name: ", 0
szAmount         db "Enter Loan Amount: ", 0
szStatus         db "Enter Status (Paid/Unpaid): ", 0
szLoanAdded      db "Loan added successfully!", 13, 10, 0
szLoanFull       db "Loan list full!", 13, 10, 0
szEnterIndex     db "Enter loan index to edit (0-based): ", 0
szEditingLoan    db "Editing Loan Record...", 13, 10, 0
szNewName        db "Enter New Name: ", 0
szNewAmount      db "Enter New Amount: ", 0
szNewStatus      db "Enter New Status: ", 0
szLoanUpdated    db "Loan updated!", 13, 10, 0
szInvalidIndex   db "Invalid loan index.", 13, 10, 0
szLoanHeader     db 13, 10, "Loan #", 0
szNameLabel      db 13, 10, "Name: ", 0
szAmountLabel    db 13, 10, "Amount: ", 0
szStatusLabel    db 13, 10, "Status: ", 0
szDivider        db 13, 10, "-------------------", 13, 10, 0
szNoLoans        db "No loans available.", 13, 10, 0

MenuText     db 13, 10, "SwiftLoan System Menu", 13, 10
            db "1. Add Loan", 13, 10
            db "2. Edit Loan", 13, 10
            db "3. View All Loans", 13, 10
            db "4. Exit", 13, 10
            db "Enter your choice: ", 0

InputBuffer  db 32 dup(?)
NameInput    db 32 dup(?)
StatusInput  db 16 dup(?)
AmountStr    db 16 dup(?)
LoanCount    dd 0
CrLf         db 13, 10, 0                 ; Define CrLf

; Loan record structure
LOAN_RECORD  STRUCT
    Name     db 32 dup(?)
    Amount   dd ?
    Status   db 16 dup(?)
LOAN_RECORD  ENDS

LoanList     LOAN_RECORD MAX_LOANS dup(<>)

.code
start:

MainLoop:
    invoke StdOut, addr MenuText
    invoke StdIn, addr InputBuffer, 32
    invoke atodw, addr InputBuffer
    mov ecx, eax

    .if ecx == 1
        call AddLoan
    .elseif ecx == 2
        call EditLoan
    .elseif ecx == 3
        call ViewLoans
    .elseif ecx == 4
        invoke ExitProcess, 0
    .endif
    jmp MainLoop

AddLoan proc
    mov eax, LoanCount
    cmp eax, MAX_LOANS
    jge AddLoan_Full

    invoke StdOut, addr CrLf
    
    ; Create string for prompts
    invoke StdOut, addr szName
    invoke StdIn, addr NameInput, 32

    invoke StdOut, addr szAmount
    invoke StdIn, addr AmountStr, 16
    invoke atodw, addr AmountStr
    mov ebx, eax

    invoke StdOut, addr szStatus
    invoke StdIn, addr StatusInput, 16

    mov esi, LoanCount
    lea edi, LoanList
    mov eax, SIZEOF LOAN_RECORD
    mul esi
    add edi, eax

    invoke lstrcpy, edi, addr NameInput
    add edi, 32
    mov [edi], ebx
    add edi, 4
    invoke lstrcpy, edi, addr StatusInput

    inc LoanCount
    invoke StdOut, addr szLoanAdded
    ret

AddLoan_Full:
    invoke StdOut, addr szLoanFull
    ret
AddLoan endp

EditLoan proc
    invoke StdOut, addr szEnterIndex
    invoke StdIn, addr InputBuffer, 16
    invoke atodw, addr InputBuffer
    mov esi, eax

    cmp esi, LoanCount
    jae InvalidIndex

    lea edi, LoanList
    mov eax, SIZEOF LOAN_RECORD
    mul esi
    add edi, eax

    invoke StdOut, addr szEditingLoan

    invoke StdOut, addr szNewName
    invoke StdIn, addr NameInput, 32
    invoke lstrcpy, edi, addr NameInput
    add edi, 32

    invoke StdOut, addr szNewAmount
    invoke StdIn, addr AmountStr, 16
    invoke atodw, addr AmountStr
    mov [edi], eax
    add edi, 4

    invoke StdOut, addr szNewStatus
    invoke StdIn, addr StatusInput, 16
    invoke lstrcpy, edi, addr StatusInput

    invoke StdOut, addr szLoanUpdated
    ret

InvalidIndex:
    invoke StdOut, addr szInvalidIndex
    ret
EditLoan endp

ViewLoans proc
    mov ecx, LoanCount
    cmp ecx, 0
    je NoLoans

    mov esi, 0
PrintLoop:
    lea edi, LoanList
    mov eax, SIZEOF LOAN_RECORD
    mul esi
    add edi, eax

    invoke StdOut, addr szLoanHeader
    mov eax, esi
    invoke dwtoa, eax, addr InputBuffer
    invoke StdOut, addr InputBuffer
    
    invoke StdOut, addr szNameLabel
    invoke StdOut, edi
    
    add edi, 32
    mov eax, [edi]
    invoke StdOut, addr szAmountLabel
    invoke dwtoa, eax, addr AmountStr
    invoke StdOut, addr AmountStr
    
    add edi, 4
    invoke StdOut, addr szStatusLabel
    invoke StdOut, edi
    
    invoke StdOut, addr szDivider

    inc esi
    cmp esi, LoanCount
    jl PrintLoop

    ret

NoLoans:
    invoke StdOut, addr szNoLoans
    ret
ViewLoans endp

end start