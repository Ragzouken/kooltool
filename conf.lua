function love.conf(t)
    t.identity = "kooltool"

	t.title = "kooltool"
	t.author = "mark wonnacott"
	t.url = "https://twitter.com/ragzouken"
	
    t.version = "0.9.1"

	t.window.width = 512
	t.window.height = 512
    t.window.resizable = true

    t.modules.joystick = false
    t.modules.physics = false
end
