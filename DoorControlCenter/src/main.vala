#!/usr/bin/env -S vala --pkg gtk+-3.0 

using Gtk;

[GtkTemplate (ui = "/org/Meteoromer/DoorControlCenter/ui/mainWindow.ui")]
public class BarWindow : Gtk.Window {
	public string ttsText {
		get { return ttsEntry.text; } 
	}

	[GtkChild]
	unowned Gtk.Entry ttsEntry;

	[GtkCallback]
	private void unlockDoor (Gtk.Button button) {
		message ("Unlocking door");
	}
	[GtkCallback]
	private void openCamera (Gtk.Button button) {
		message ("Opening camera");
	}
	[GtkCallback]
	private void sendTTSMessage (Gtk.Button button) {
		message ("Sending TTS message: %s\n", ttsEntry.text);
	}

	[GtkCallback]
	private void entry_changed (Gtk.Editable editable) {
		message ("Entry changed, text: %s\n", ttsEntry.text);
		notify_property ("ttsText");
	}
}

public void main (string[] args) {
	Gtk.init (ref args);

	var app = new BarWindow ();
	app.show_all ();
	Gtk.main ();
}