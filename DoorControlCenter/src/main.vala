#!/usr/bin/env -S vala --pkg gtk+-3.0 --pkg gstreamer-1.0 --pkg gstreamer-video-1.0 --pkg gstreamer-rtsp-1.0

using Gtk;
using Gst;

[GtkTemplate (ui = "/org/Meteoromer/DoorControlCenter/ui/mainWindow.ui")]
public class MainWindow : Gtk.Window {
	public string ttsText {
		get { return ttsEntry.text; } 
	}

	[GtkChild]
	unowned Gtk.Revealer videoRevealer;
	
	[GtkChild]
	unowned Gtk.Box videoBox;

	
	[GtkChild]
	unowned Gtk.Entry ttsEntry;
	
	[GtkChild]
	unowned Gtk.Statusbar statusBar;
	
	private Gtk.Widget videoWidget;

	[GtkCallback]
	private void unlockDoor (Gtk.Button button) {
		message ("Unlocking door");
		statusBar.push (0, "Unlocking door...");
	}
	[GtkCallback]
	private void openCamera (Gtk.Button button) {
		button.label = videoRevealer.reveal_child ? "Open Camera" : "Close Camera";
		message ("Opening camera");
		statusBar.push (0, "Opening camera...");
		videoRevealer.reveal_child = videoRevealer.reveal_child ? false : true;
		//TODO: Start RTSP streaming
		var gtksink = Gst.ElementFactory.make("gtksink", "gtksink");
		var playbin = Gst.ElementFactory.make("playbin", "playbin");
		var val = GLib.Value(typeof(Gtk.Widget));
		gtksink.get_property("widget",ref val);
		videoWidget = (Gtk.Widget)val.get_object();
		videoBox.pack_start (videoWidget, false, false, 0);
		videoBox.reorder_child (videoWidget, 0);
		videoWidget.show();
		playbin.set_property("video-sink", gtksink);
		playbin.set_property("uri", "https://gstreamer.freedesktop.org/data/media/sintel_trailer-480p.webm");
		playbin.set_state (Gst.State.PLAYING);
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
	Gst.init (ref args);

	var app = new MainWindow ();
	app.show_all ();
	Gtk.main ();
}