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
	private Gst.Pipeline pipeline;
	
	public MainWindow(){
		//TODO: Change source to a real camera source
		var source = Gst.ElementFactory.make("videotestsrc", "source");
		var gtksink = Gst.ElementFactory.make("gtksink", "gtksink");
		var val = GLib.Value(typeof(Gtk.Widget));
		gtksink.get_property("widget",ref val);
		videoWidget = (Gtk.Widget)val.get_object();
		videoBox.pack_start(videoWidget, true, false, 0);
		videoBox.reorder_child (videoWidget, 0);
		pipeline = new Gst.Pipeline ("pipeline");
		pipeline.add_many (source, gtksink);
		if(source.link(gtksink) == false) {
			warning ("Failed to link source and gtksink");
		}

		pipeline.set_state (Gst.State.PLAYING);
		var ret = pipeline.get_state(null, null, 2 * Gst.SECOND);
		if(ret == Gst.StateChangeReturn.SUCCESS || ret == Gst.StateChangeReturn.ASYNC){
			var sinkCaps = gtksink.get_static_pad("sink").get_current_caps();
			weak Gst.Structure structure = sinkCaps.get_structure(0);
			int width = 0, height = 0;
			structure.get_int("width", out width);
			structure.get_int("height", out height);
			videoWidget.set_size_request (width, height);
		}
		videoWidget.show();
		pipeline.set_state(Gst.State.PAUSED);
	}

	[GtkCallback]
	private void unlockDoor (Gtk.Button button) {
		message ("Unlocking door");
		statusBar.push (0, "Unlocking door...");
	}
	[GtkCallback]
	private void openCamera (Gtk.Button button) {
		if(videoRevealer.reveal_child){
			videoRevealer.reveal_child = false;
			message ("Closing camera");
			pipeline.set_state (Gst.State.PAUSED);
			statusBar.push (0, "Closing camera...");

		}
		else{
			videoRevealer.reveal_child = true;
			message ("Opening camera");
			pipeline.set_state (Gst.State.PLAYING);
			statusBar.push (0, "Opening camera...");
		}
		button.label = videoRevealer.reveal_child ? "Close Camera" : "Open Camera";
		
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