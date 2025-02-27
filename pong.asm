[BITS 16]
[ORG 0x2000]

start:
    cli
    mov ax, 0x0200
    mov ds, ax
    mov ss, ax
    mov sp, 0xFFFE
    call set_graphics_mode

    mov ax, RECTANGLE_HEIGHT
    shr ax, 1
    mov word [line_pos], ax
    call draw_rectangle
    call draw_line

    mov word [ball_x], center_x + (RECTANGLE_WIDTH / 2)
    mov word [ball_y], center_y + (RECTANGLE_HEIGHT / 2)
    mov word [ball_dx], 1
    mov word [ball_dy], 1

main_loop:
    call erase_ball
    call move_ball
    call draw_ball
    call line_control
    call delay           ; Delay for slower ball speed (higher = slower)
    jmp main_loop

set_graphics_mode:
    mov ax, 0x13           ; Set graphics mode
    int 0x10
    ret

SCREEN_WIDTH    equ 320
SCREEN_HEIGHT   equ 200
RECTANGLE_WIDTH equ 230
RECTANGLE_HEIGHT equ 140
COLOR           equ 0x0F
PLAYER_LENGTH   equ 17
BALL_SPEED      equ 30000000  ; Adjusted to fit dword, slower speed
BALL_SIZE       equ 4
BALL_BOUNCE_OFFSET equ 1

center_x equ (SCREEN_WIDTH / 2) - (RECTANGLE_WIDTH / 2)
center_y equ (SCREEN_HEIGHT / 2) - (RECTANGLE_HEIGHT / 2)
last_x   equ center_x + RECTANGLE_WIDTH - 1
last_y   equ center_y + RECTANGLE_HEIGHT - 1

draw_rectangle:
    mov si, center_x
.top_loop:
    mov cx, si
    mov dx, center_y
    mov ah, 0x0C
    mov al, COLOR
    mov bh, 0x00
    int 0x10
    inc si
    cmp si, last_x
    jbe .top_loop
    mov si, center_x
.bottom_loop:
    mov cx, si
    mov dx, last_y
    mov ah, 0x0C
    mov al, COLOR
    mov bh, 0x00
    int 0x10
    inc si
    cmp si, last_x
    jbe .bottom_loop
    mov dx, center_y
.left_loop:
    mov cx, center_x
    mov ah, 0x0C
    mov al, COLOR
    mov bh, 0x00
    int 0x10
    inc dx
    cmp dx, last_y
    jbe .left_loop
    mov dx, center_y
.right_loop:
    mov cx, last_x
    mov ah, 0x0C
    mov al, COLOR
    mov bh, 0x00
    int 0x10
    inc dx
    cmp dx, last_y
    jbe .right_loop
    ret

LINE_X     equ center_x + 10
LINE_LENGTH equ PLAYER_LENGTH
LINE_COLOR  equ 0x0A

line_control:
    mov ah, 0x01          ; Check keyboard status
    int 0x16
    jz no_key
    mov ah, 0x00
    int 0x16
    cmp al, 'w'           ; Move up on 'w'
    je move_up
    cmp al, 's'           ; Move down on 's'
    je move_down
no_key:
    ret

move_up:
    call erase_line
    mov ax, [line_pos]
    cmp ax, 1             ; Prevent moving above screen
    jbe skip_up
    dec word [line_pos]
skip_up:
    call draw_line
    ret

move_down:
    call erase_line
    mov ax, [line_pos]
    mov bx, RECTANGLE_HEIGHT
    sub bx, (PLAYER_LENGTH + 1)   ; Check for bottom edge
    cmp ax, bx
    jae skip_down
    inc word [line_pos]
skip_down:
    call draw_line
    ret

draw_line:
    mov di, 0
.draw_line_loop:
    mov ax, center_y
    add ax, [line_pos]
    add ax, di
    mov dx, ax
    mov cx, LINE_X
    mov ah, 0x0C
    mov al, LINE_COLOR
    mov bh, 0x00
    int 0x10
    inc di
    cmp di, LINE_LENGTH  ; Stop after drawing the line length
    jl .draw_line_loop
    ret

erase_line:
    mov di, 0
.erase_line_loop:
    mov ax, center_y
    add ax, [line_pos]
    add ax, di
    mov dx, ax
    mov cx, LINE_X
    mov ah, 0x0C
    mov al, 0x00         ; Erase line with color 0x00
    mov bh, 0x00
    int 0x10
    inc di
    cmp di, LINE_LENGTH
    jl .erase_line_loop
    ret

BALL_COLOR equ 0x0C

ball_x  dw 0
ball_y  dw 0
ball_dx dw 0
ball_dy dw 0

move_ball:
    mov ax, [ball_x]
    add ax, [ball_dx]    ; Move ball by dx
    cmp ax, center_x + BALL_BOUNCE_OFFSET
    jle reverse_x        ; Ball hits left edge
    cmp ax, last_x - BALL_SIZE - BALL_BOUNCE_OFFSET
    jge reverse_x        ; Ball hits right edge
    mov [ball_x], ax

    mov ax, [ball_y]
    add ax, [ball_dy]    ; Move ball by dy
    cmp ax, center_y + BALL_BOUNCE_OFFSET
    jle reverse_y        ; Ball hits top edge
    cmp ax, last_y - BALL_SIZE - BALL_BOUNCE_OFFSET
    jge reverse_y        ; Ball hits bottom edge
    mov [ball_y], ax
    ret

reverse_x:
    neg word [ball_dx]   ; Reverse X direction
    mov ax, [ball_x]
    add ax, [ball_dx]    ; Update X position after bounce
    mov [ball_x], ax
    ret

reverse_y:
    neg word [ball_dy]   ; Reverse Y direction
    mov ax, [ball_y]
    add ax, [ball_dy]    ; Update Y position after bounce
    mov [ball_y], ax
    ret

draw_ball:
    mov si, 0
.draw_ball_loop:
    mov di, 0
.draw_ball_inner_loop:
    mov cx, [ball_x]
    add cx, si
    mov dx, [ball_y]
    add dx, di
    mov ah, 0x0C
    mov al, BALL_COLOR
    mov bh, 0x00
    int 0x10
    inc di
    cmp di, BALL_SIZE    ; Loop to draw the ball (its size)
    jl .draw_ball_inner_loop
    inc si
    cmp si, BALL_SIZE
    jl .draw_ball_loop
    ret

erase_ball:
    mov si, 0
.erase_ball_loop:
    mov di, 0
.erase_ball_inner_loop:
    mov cx, [ball_x]
    add cx, si
    mov dx, [ball_y]
    add dx, di
    mov ah, 0x0C
    mov al, 0x00
    mov bh, 0x00
    int 0x10
    inc di
    cmp di, BALL_SIZE
    jl .erase_ball_inner_loop
    inc si
    cmp si, BALL_SIZE
    jl .erase_ball_loop
    ret

delay:
    mov cx, BALL_SPEED    ; The delay value controls ball speed
.delay_outer:
    mov bx, 100          ; Inner loop for extra delay effect
.delay_inner:
    nop
    dec bx
    jnz .delay_inner
    loop .delay_outer
    ret

line_pos dw 0
