; EmployeeMenu.asm
.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\masm32.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\masm32.lib

Employee STRUCT
        empID db 32 dup(?)
        empName db 64 dup(?)
        empPosition db 64 dup(?)
        empSalary db 32 dup(?)
        empDateHired db 32 dup(?)
Employee ENDS

.data
    MAX_EMPLOYEES equ 100
    employeeArray Employee MAX_EMPLOYEES dup(<>)
    employeeCount DWORD 0

    employee1 Employee <>

    promptMessage      db "Enter a number (1-4): ", 10,13,0
    inputBuffer        db 16 dup(0)
    createMsg          db "1. Create a new employee profile", 10, 13, 0
    searchMsg             db "2. Search employee profile", 10, 13, 0
    deleteMsg          db "3. Delete existing employee profile", 10, 13, 0
    exitMsg            db "4. Exit", 10, 13, 0
    invalidMsg         db "Invalid input!", 10, 13, 0
    empDeletedMsg      db "Employee successfully deleted", 10, 13, 0
    choicePrompt       db "Enter choice:", 10, 13, 0

    
    empFoundMsg db "Employee found!", 10, 13, 0
    empNotFoundMsg db "Employee not found", 10, 13, 0

    ; Employee prompts
    empIdPrompt       db "Enter Employee ID: ",10,13,0
    empNamePrompt     db "Enter Employee Name: ",10,13,0
    empPositionPrompt db "Enter Position: ",10,13,0
    empSalaryPrompt   db "Enter Salary: ",10,13,0
    empDatePrompt     db "Enter Date Hired: ",10,13,0
    newLine db 10,13,0
    

    ; Employee data buffers
    empID             db 32 dup(0)
    empName           db 64 dup(0)
    empPosition       db 64 dup(0)
    empSalary         db 32 dup(0)
    empDateHired      db 32 dup(0)

.code
start:

MainMenu:
    invoke StdOut, addr promptMessage
    invoke StdOut, addr createMsg
    invoke StdOut, addr searchMsg
    invoke StdOut, addr deleteMsg
    invoke StdOut, addr exitMsg
    invoke StdOut, addr choicePrompt
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    invoke atodw, addr inputBuffer
    mov eax, eax  ; EAX = choice

    cmp eax, 1
    je CreateProfile
    cmp eax, 2
    je SearchProfile
    cmp eax, 3
    je DeleteProfile
    cmp eax, 4
    je ExitProgram
    jmp InvalidInput

InvalidInput:
    invoke StdOut, addr invalidMsg
    jmp Done

CreateProfile:

    invoke ClearScreen
    ; Check if we have space
    mov eax, employeeCount
    cmp eax, MAX_EMPLOYEES
    jge ArrayFull

    ; Get pointer to next free employee
    mov ecx, SIZEOF Employee
    mul ecx                        ; eax = employeeCount * SIZEOF Employee
    lea esi, employeeArray
    add esi, eax                   ; ESI = &employeeArray[employeeCount]

    invoke StdOut, addr createMsg

    ; Employee ID
    invoke StdOut, addr empIdPrompt
    invoke StdIn, addr employee1.empID, sizeof employee1.empID

    ; Employee Name
    invoke StdOut, addr empNamePrompt
    invoke StdIn, addr employee1.empName, sizeof employee1.empName

    ; Position
    invoke StdOut, addr empPositionPrompt
    invoke StdIn, addr employee1.empPosition, sizeof employee1.empPosition

    ; Salary
    invoke StdOut, addr empSalaryPrompt
    invoke StdIn, addr employee1.empSalary, sizeof employee1.empSalary

    ; Date Hired
    invoke StdOut, addr empDatePrompt
    invoke StdIn, addr employee1.empDateHired, sizeof employee1.empDateHired

    ; Copy employee1 into employeeArray[employeeCount]
    mov ecx, SIZEOF Employee
    lea esi, employee1

    mov eax, employeeCount
    mov edx, SIZEOF Employee
    mul edx                      ; EAX = employeeCount * SIZEOF Employee
    lea edi, employeeArray
    add edi, eax                 ; EDI = &employeeArray[employeeCount]

    mov ecx, SIZEOF Employee
    rep movsb

    inc employeeCount
    
    jmp MainMenu

ArrayFull:
    invoke StdOut, addr invalidMsg ; Or a "list full" message
    jmp Done

SearchProfile:
    invoke ClearScreen
    ; Ask for employee ID
    invoke StdOut, addr searchMsg
    invoke StdOut, addr empIdPrompt
    invoke StdIn, addr inputBuffer, sizeof inputBuffer
    mov ebx, eax  ; EBX = employee ID to search for

    ; Start searching for the employee in the array
    lea esi, employeeArray
    mov ecx, employeeCount  ; How many employees to search through

    ; Search loop
    xor esi, esi  ; ESI = loop index
    
SearchLoop:
    cmp esi, employeeCount
    jge EmployeeNotFound

    mov eax, esi
    mov ecx, SIZEOF Employee
    mul ecx
    lea edi, employeeArray
    add edi, eax  ; EDI = &employeeArray[esi]

    lea eax, [edi + offset Employee.empID]
    invoke lstrcmp, eax, addr inputBuffer
    cmp eax, 0
    je EmployeeFound

    inc esi
    jmp SearchLoop

EmployeeFound:
    invoke ClearScreen
    ; Display the employee details
    invoke StdOut, addr empFoundMsg

    ;invoke StdOut, addr edi.empID
    lea eax, [edi]
    add eax, offset Employee.empID
    invoke StdOut, eax
    invoke StdOut, addr newLine

    ;invoke StdOut, addr edi.empName
    lea eax, [edi]
    add eax, offset Employee.empName
    invoke StdOut, eax
    invoke StdOut, addr newLine
    
    ;invoke StdOut, addr edi.empPosition
    lea eax, [edi]
    add eax, offset Employee.empPosition
    invoke StdOut, eax
    invoke StdOut, addr newLine

    ;invoke StdOut, addr edi.empSalary
    lea eax, [edi]
    add eax, offset Employee.empSalary
    invoke StdOut, eax
    invoke StdOut, addr newLine

    ;invoke StdOut, addr edi.empDateHired
    lea eax, [edi]
    add eax, offset Employee.empDateHired
    invoke StdOut, eax
    invoke StdOut, addr newLine

    ; Go back to the main menu
    jmp MainMenu

EmployeeNotFound:
    ; No employee found
    invoke StdOut, addr empNotFoundMsg
    jmp MainMenu

DeleteProfile:
    invoke ClearScreen
    ; Ask for employee ID to delete
    invoke StdOut, addr deleteMsg
    invoke StdOut, addr empIdPrompt
    invoke StdIn, addr inputBuffer, sizeof inputBuffer

    ; Start searching for the employee
    lea edi, employeeArray
    mov ecx, employeeCount

    xor esi, esi   ; ESI = index

SearchDeleteLoop:
    cmp esi, ecx
    jge EmployeeNotFound

    ; Calculate &employeeArray[esi]
    mov eax, esi
    mov ebx, SIZEOF Employee
    mul ebx
    lea edi, employeeArray
    add edi, eax  ; EDI = &employeeArray[esi]

    ; Compare empID
    lea eax, [edi + offset Employee.empID]
    invoke lstrcmp, eax, addr inputBuffer
    cmp eax, 0
    je DeleteFound

    inc esi
    jmp SearchDeleteLoop

DeleteFound:
    invoke ClearScreen
    ; ESI = index of employee to delete

    ; Check if it's the last employee — no need to shift
    mov eax, employeeCount
    dec eax
    cmp esi, eax
    jge SkipShift

    ; Start shifting remaining entries left
    mov ebx, SIZEOF Employee

ShiftLoop:
    ; Calculate source address = employeeArray[esi + 1]
    mov eax, esi
    inc eax
    mul ebx
    lea esi, employeeArray
    add esi, eax

    ; Calculate destination address = employeeArray[esi]
    mov eax, esi
    mul ebx
    lea edi, employeeArray
    add edi, eax

    ; Copy employee structure
    mov ecx, SIZEOF Employee
    mov esi, esi
    mov edi, edi
    rep movsb

    inc esi
    mov eax, employeeCount
    dec eax
    cmp esi, eax
    jl ShiftLoop

SkipShift:
    ; Decrement employee count
    dec employeeCount

    invoke StdOut, addr empDeletedMsg
    jmp MainMenu
    
ExitProgram:
    invoke StdOut, addr exitMsg
    jmp Done

Done:
    invoke ExitProcess, 0
end start
