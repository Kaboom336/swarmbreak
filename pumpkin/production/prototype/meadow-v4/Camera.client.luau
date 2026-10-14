-- Press V for concept view, B for north-up plan, N to return to player camera.
local UIS = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.V then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(Vector3.new(0,220,460),Vector3.new(0,-30,-10))
        camera.FieldOfView = 29.25
    elseif input.KeyCode == Enum.KeyCode.B then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(Vector3.new(0,540,0),Vector3.zero,Vector3.new(0,0,-1))
        camera.FieldOfView = 40
    elseif input.KeyCode == Enum.KeyCode.N then camera.CameraType = Enum.CameraType.Custom end
end)
