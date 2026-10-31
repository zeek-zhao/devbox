package main

import "fmt"

type Button interface {
	Family() string
}

type TextBox interface {
	Family() string
}

type Factory interface {
	CreateButton() Button
	CreateTextBox() TextBox
}

type lightButton struct{}
type lightTextBox struct{}
type darkButton struct{}
type darkTextBox struct{}

func (lightButton) Family() string  { return "light" }
func (lightTextBox) Family() string { return "light" }
func (darkButton) Family() string   { return "dark" }
func (darkTextBox) Family() string  { return "dark" }

type LightFactory struct{}
type DarkFactory struct{}

func (LightFactory) CreateButton() Button   { return lightButton{} }
func (LightFactory) CreateTextBox() TextBox { return lightTextBox{} }
func (DarkFactory) CreateButton() Button    { return darkButton{} }
func (DarkFactory) CreateTextBox() TextBox  { return darkTextBox{} }

func ShowFamily(factory Factory) string {
	button, textBox := factory.CreateButton(), factory.CreateTextBox()
	fmt.Printf("button=%s textbox=%s matched=%t\n",
		button.Family(), textBox.Family(), button.Family() == textBox.Family())
	return button.Family()
}

func main() {
	light := ShowFamily(LightFactory{})
	dark := ShowFamily(DarkFactory{})
	fmt.Printf("different families: %t\n", light != dark)
}
