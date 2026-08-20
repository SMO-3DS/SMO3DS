FrameCounter = {}

function FrameCounter:Create()
    self.accumTime = 0
    self.frameCount = 0
end

function FrameCounter:Tick(deltaTime)
    self.accumTime = self.accumTime + deltaTime
    self.frameCount = self.frameCount + 1

    if self.accumTime >= 0.5 then
        local fps = math.floor(self.frameCount / self.accumTime)
        self:SetText("FPS: " .. fps)

        self.accumTime = 0
        self.frameCount = 0
    end
end

return FrameCounter
