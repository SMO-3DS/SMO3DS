-- BasicPlayerController.lua
-- Simpler First-Person-Controller für den 3DS.
-- Gedacht für einen Node (z.B. Box3D/Cube), der eine Camera3D als Child hat.
--
-- Steuerung (3DS):
--   Circle Pad (linker Stick)  -> Bewegung vor/zurück/seitwärts
--   C-Stick (rechter Stick)    -> Umschauen (Kamera-Rotation)
--   A                          -> Springen (nur wenn am Boden)
--
-- WICHTIG: Node3D-, Input- und Vector-Funktionen unten sind gegen die
-- offizielle Octave-Doku geprüft, auf der Polyphase basiert. Der Lifecycle-Teil
-- (wie genau Start/Tick auf einem Script-Table aufgerufen werden und wie man an
-- den "eigenen" Node kommt) konnte ich nicht 1:1 verifizieren - vergleich das
-- bei Bedarf mit einem der mitgelieferten Demo-Scripts (z.B. FirstPersonController.lua).
--
-- Schwerkraft ist hier bewusst simpel gehalten: fixer Boden-Level statt echtem
-- Raycast gegen die Welt. Für "echte" Boden-Kollision (z.B. auf unebenem Terrain)
-- später ggf. auf die World/Primitive3D Raycast-API umstellen.

BasicPlayerController = {}

-- Bewegungsgeschwindigkeit in Units/Sekunde
BasicPlayerController.moveSpeed = 3.0

-- Umschau-Geschwindigkeit in Grad/Sekunde
BasicPlayerController.lookSpeed = 90.0

-- Deadzone für die Sticks, damit der Controller nicht "driftet"
BasicPlayerController.deadzone = 0.15

-- Aktuelle Kamera-Neigung (Pitch), separat getrackt, damit wir sie clampen können
BasicPlayerController.pitch = 0.0

-- Schwerkraft in Units/Sekunde^2 (negativ = nach unten)
BasicPlayerController.gravity = -9.8

-- Fixer Boden-Level in World-Space Y. Simple Variante ohne echte Kollisionsabfrage -
-- der Cube fällt bis hierhin und bleibt dann stehen.
BasicPlayerController.groundLevel = 0.0

-- Sprungkraft in Units/Sekunde
BasicPlayerController.jumpForce = 5.0

-- Aktuelle vertikale Geschwindigkeit
BasicPlayerController.velocityY = 0.0

-- Ob der Cube gerade auf dem Boden steht
BasicPlayerController.isGrounded = false

function BasicPlayerController:Create()
    -- self ist hier der Node selbst (der Cube).
    -- Kamera ist das erste Child dieses Nodes.
    self.camera = self:GetChild(0)
    self.pitch = 0.0
    self.velocityY = 0.0
    self.isGrounded = false
end

function BasicPlayerController:Tick(deltaTime)
    self:HandleMovement(deltaTime)
    self:HandleLook(deltaTime)
    self:HandleGravity(deltaTime)
end

function BasicPlayerController:ApplyDeadzone(value)
    if math.abs(value) < self.deadzone then
        return 0.0
    end
    return value
end

function BasicPlayerController:HandleMovement(deltaTime)
    -- Circle Pad Achsen abfragen (Werte typischerweise -1 bis 1)
    local moveX = self:ApplyDeadzone(Input.GetGamepadAxis(Gamepad.AxisLX))
    local moveY = self:ApplyDeadzone(Input.GetGamepadAxis(Gamepad.AxisLY))

    if moveX == 0.0 and moveY == 0.0 then
        return
    end

    -- Vor-/Rückwärts- und Rechts-Vektor des Cubes (nur horizontal, Y ignorieren)
    local forward = self:GetForwardVector()
    forward.y = 0.0
    forward = forward:Normalize()

    local right = self:GetRightVector()
    right.y = 0.0
    right = right:Normalize()

    local moveDir = forward * moveY + right * moveX
    local moveAmount = self.moveSpeed * deltaTime

    local pos = self:GetPosition()
    pos = pos + moveDir * moveAmount
    self:SetPosition(pos)
end

function BasicPlayerController:HandleLook(deltaTime)
    -- C-Stick für Umschauen
    local lookX = self:ApplyDeadzone(Input.GetGamepadAxis(Gamepad.AxisRX))
    local lookY = self:ApplyDeadzone(Input.GetGamepadAxis(Gamepad.AxisRY))

    if lookX == 0.0 and lookY == 0.0 then
        return
    end

    -- Horizontale Drehung (Yaw) auf dem Cube selbst -> dreht auch die Bewegungsrichtung mit
    local yawDelta = lookX * self.lookSpeed * deltaTime
    self:AddRotation(Vec(0, yawDelta, 0))

    -- Vertikale Drehung (Pitch) nur auf der Kamera, geclampt, damit man sich nicht überschlägt
    self.pitch = self.pitch - (lookY * self.lookSpeed * deltaTime)
    if self.pitch > 89.0 then
        self.pitch = 89.0
    elseif self.pitch < -89.0 then
        self.pitch = -89.0
    end

    if self.camera ~= nil then
        self.camera:SetRotation(Vec(self.pitch, 0, 0))
    end
end

function BasicPlayerController:HandleGravity(deltaTime)
    local debugPos = self:GetPosition()
    Log.Debug("Gravity tick - posY=" .. tostring(debugPos.y) .. " velY=" .. tostring(self.velocityY) .. " grounded=" .. tostring(self.isGrounded))

    -- Sprung: A-Knopf, nur wenn gerade am Boden
    if self.isGrounded and Input.IsGamepadPressed(Gamepad.A) then
        self.velocityY = self.jumpForce
        self.isGrounded = false
    end

    -- Schwerkraft auf die vertikale Geschwindigkeit anwenden
    self.velocityY = self.velocityY + self.gravity * deltaTime

    local pos = self:GetPosition()
    pos.y = pos.y + self.velocityY * deltaTime

    -- Simple Boden-Kollision: fixer Y-Level statt echtem Raycast
    if pos.y <= self.groundLevel then
        pos.y = self.groundLevel
        self.velocityY = 0.0
        self.isGrounded = true
    else
        self.isGrounded = false
    end

    self:SetPosition(pos)
end

return BasicPlayerController
