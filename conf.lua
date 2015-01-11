function love.conf(t)
    t.identity = "kooltool"

	t.title = "kooltool sketch"
	t.author = "mark wonnacott"
	t.url = "https://twitter.com/ragzouken"
	
    t.version = "0.9.1"

	t.window.width = 768
	t.window.height = 768
    t.window.resizable = true

    t.modules.joystick = false
    t.modules.physics = false
end
