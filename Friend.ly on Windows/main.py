import pygame
import json
import os
import random
import base64
import sys
from pathlib import Path

pygame.init()

APP_NAME = "Friendly"

def resource_path(relative_path):
    if hasattr(sys, "_MEIPASS"):
        return os.path.join(sys._MEIPASS, relative_path)
    return os.path.join(os.path.abspath("."), relative_path)

def get_user_data_path():
    base = Path(os.getenv("APPDATA"))
    app_dir = base / APP_NAME
    app_dir.mkdir(parents=True, exist_ok=True)
    return app_dir / "users.json"

dataFile = get_user_data_path()

screen_resolutions = {
    '1920x1080': (1920, 1080),
    '1080x640': (1080, 640)
}
currentResolution = '1080x640'

screenW, screenH = screen_resolutions[currentResolution]
screen = pygame.display.set_mode((screenW, screenH))
pygame.display.set_caption("Friendly")
clock = pygame.time.Clock()

def load_font(name, size, bold=False):
    try:
        return pygame.font.SysFont(name, size, bold=bold)
    except:
        return pygame.font.Font(None, size)

titleFont = load_font("comic sans ms", int(screenH * 0.09), bold=True)
font = load_font("arial", int(screenH * 0.045))
small = load_font("arial", int(screenH * 0.03))

greenLight = (102, 255, 153)
greenDark = (0, 153, 51)
white = (255, 255, 255)
black = (0, 0, 0)
buttonTop = (0, 200, 0)
buttonBottom = (0, 150, 0)
inputColor = white

SECRET_KEY = "friendly_key"

def xor_encrypt(text):
    encrypted = "".join(
        chr(ord(c) ^ ord(SECRET_KEY[i % len(SECRET_KEY)]))
        for i, c in enumerate(text)
    )
    return base64.b64encode(encrypted.encode()).decode()

def xor_decrypt(encoded):
    decoded = base64.b64decode(encoded).decode()
    return "".join(
        chr(ord(c) ^ ord(SECRET_KEY[i % len(SECRET_KEY)]))
        for i, c in enumerate(decoded)
    )

def load_users():
    if not dataFile.exists():
        dataFile.write_text(json.dumps({}))
    return json.loads(dataFile.read_text())

def save_users(users):
    dataFile.write_text(json.dumps(users))

users = load_users()

mode = "menu"
mode_colors = {}

def get_mode_color(mode):
    if mode not in mode_colors:
        mode_colors[mode] = [random.randint(60, 255) for _ in range(3)]
    return mode_colors[mode]

class InputBox:
    def __init__(self, w, h, pwd=False):
        self.rect = pygame.Rect(0, 0, w, h)
        self.text = ""
        self.active = False
        self.pwd = pwd

    def handle(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN:
            self.active = self.rect.collidepoint(event.pos)
        if event.type == pygame.KEYDOWN and self.active:
            if event.key == pygame.K_BACKSPACE:
                self.text = self.text[:-1]
            elif event.key != pygame.K_RETURN:
                self.text += event.unicode

    def draw(self, surface):
        pygame.draw.rect(surface, inputColor, self.rect, border_radius=12)
        display = "*" * len(self.text) if self.pwd else self.text
        txt = font.render(display, True, black)
        surface.blit(txt, (self.rect.x + 10, self.rect.centery - txt.get_height() // 2))
        if self.active:
            pygame.draw.rect(surface, buttonBottom, self.rect, 3, border_radius=12)

class GradientButton:
    def __init__(self, w, h, text):
        self.rect = pygame.Rect(0, 0, w, h)
        self.text = text
        self.hovered = False

    def clicked(self, event):
        return event.type == pygame.MOUSEBUTTONDOWN and self.rect.collidepoint(event.pos)

    def check_hover(self, pos):
        self.hovered = self.rect.collidepoint(pos)

    def draw(self, surface):
        button_surf = pygame.Surface(self.rect.size, pygame.SRCALPHA)
        for y in range(self.rect.h):
            ratio = y / self.rect.h
            r = int(buttonTop[0] * (1 - ratio) + buttonBottom[0] * ratio)
            g = int(buttonTop[1] * (1 - ratio) + buttonBottom[1] * ratio)
            b = int(buttonTop[2] * (1 - ratio) + buttonBottom[2] * ratio)
            pygame.draw.line(button_surf, (r, g, b), (0, y), (self.rect.w, y))

        mask = pygame.Surface(self.rect.size, pygame.SRCALPHA)
        pygame.draw.rect(mask, (255, 255, 255), mask.get_rect(), border_radius=12)
        button_surf.blit(mask, (0, 0), special_flags=pygame.BLEND_RGBA_MIN)

        surface.blit(button_surf, self.rect)
        pygame.draw.rect(surface, black, self.rect, 2, border_radius=12)

        txt = font.render(self.text, True, white)
        surface.blit(txt, txt.get_rect(center=self.rect.center))

login_user = InputBox(300, 50)
login_pass = InputBox(300, 50, True)
signup_user = InputBox(300, 50)
signup_pass = InputBox(300, 50, True)

btn_menu_login = GradientButton(300, 50, "Login")
btn_menu_signup = GradientButton(300, 50, "Sign Up")
btn_login_screen = GradientButton(300, 50, "Login")
btn_signup_screen = GradientButton(300, 50, "Sign Up")
btn_back = GradientButton(150, 40, "Back")

nav_buttons = [
    GradientButton(120, 50, "Home"),
    GradientButton(120, 50, "Chat"),
    GradientButton(120, 50, "Profile"),
    GradientButton(120, 50, "Settings")
]

def update_layout():
    cx = screenW // 2
    login_user.rect.center = (cx, int(screenH * 0.32))
    login_pass.rect.center = (cx, int(screenH * 0.46))
    signup_user.rect.center = login_user.rect.center
    signup_pass.rect.center = login_pass.rect.center
    btn_login_screen.rect.center = (cx, int(screenH * 0.60))
    btn_signup_screen.rect.center = btn_login_screen.rect.center
    btn_menu_login.rect.center = (cx, int(screenH * 0.45))
    btn_menu_signup.rect.center = (cx, int(screenH * 0.55))
    btn_back.rect.topleft = (20, 20)
    bar_y = int(screenH * 0.85)
    spacing = screenW // (len(nav_buttons) + 1)
    for i, btn in enumerate(nav_buttons):
        btn.rect.center = (spacing * (i + 1), bar_y)

update_layout()

def draw_gradient():
    for y in range(screenH):
        ratio = y / screenH
        r = int(greenLight[0] * (1 - ratio) + greenDark[0] * ratio)
        g = int(greenLight[1] * (1 - ratio) + greenDark[1] * ratio)
        b = int(greenLight[2] * (1 - ratio) + greenDark[2] * ratio)
        pygame.draw.line(screen, (r, g, b), (0, y), (screenW, y))

running = True
while running:
    mouse = pygame.mouse.get_pos()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            save_users(users)
            running = False

        if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
            save_users(users)
            running = False

        if mode == "menu":
            if btn_menu_login.clicked(event):
                mode = "login"
            if btn_menu_signup.clicked(event):
                mode = "signup"

        elif mode == "login":
            login_user.handle(event)
            login_pass.handle(event)
            if btn_login_screen.clicked(event):
                for u, p in users.items():
                    if xor_decrypt(u) == login_user.text and xor_decrypt(p) == login_pass.text:
                        mode = "main"
            if btn_back.clicked(event):
                mode = "menu"

        elif mode == "signup":
            signup_user.handle(event)
            signup_pass.handle(event)
            if btn_signup_screen.clicked(event):
                users[xor_encrypt(signup_user.text)] = xor_encrypt(signup_pass.text)
                save_users(users)
                mode = "menu"
            if btn_back.clicked(event):
                mode = "menu"

        elif mode in ["main", "home", "chat", "profile", "settings"]:
            for btn in nav_buttons:
                if btn.clicked(event):
                    mode = "main" if btn.text == "Home" else btn.text.lower()

    for btn in [btn_menu_login, btn_menu_signup, btn_login_screen,
                btn_signup_screen, btn_back] + nav_buttons:
        btn.check_hover(mouse)

    if mode in ["menu", "login", "signup"]:
        draw_gradient()
    else:
        screen.fill(white)

    pygame.draw.rect(screen, get_mode_color(mode), (screenW - 60, 20, 40, 40))

    title = titleFont.render("Friendly", True, white if mode in ["menu","login","signup"] else greenDark)
    screen.blit(title, title.get_rect(center=(screenW // 2, int(screenH * 0.12))))

    if mode in ["login", "signup"]:
        screen.blit(small.render("Username", True, white), (login_user.rect.x, login_user.rect.y - 28))
        screen.blit(small.render("Password", True, white), (login_pass.rect.x, login_pass.rect.y - 28))

    if mode == "menu":
        btn_menu_login.draw(screen)
        btn_menu_signup.draw(screen)
    elif mode == "login":
        login_user.draw(screen)
        login_pass.draw(screen)
        btn_login_screen.draw(screen)
        btn_back.draw(screen)
    elif mode == "signup":
        signup_user.draw(screen)
        signup_pass.draw(screen)
        btn_signup_screen.draw(screen)
        btn_back.draw(screen)
    else:
        screen.blit(titleFont.render(mode.upper(), True, greenDark),
                    (screenW // 2 - 100, screenH // 2))
        pygame.draw.rect(screen, greenDark, (0, int(screenH * 0.80), screenW, int(screenH * 0.20)))
        for btn in nav_buttons:
            btn.draw(screen)

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
