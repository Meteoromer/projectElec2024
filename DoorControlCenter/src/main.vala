#!/usr/bin/env -S vala --pkg gtk+-3.0 --pkg gstreamer-1.0 --pkg gstreamer-video-1.0 --pkg gstreamer-rtsp-1.0

using Gtk;
using Gst;
using Soup;

[GtkTemplate (ui = "/org/Meteoromer/DoorControlCenter/ui/mainWindow.ui")]
public class MainWindow : Gtk.Window {
	public string ttsText {
		get { return ttsEntry.text; } 
	}
	
	[GtkChild]
	unowned Gtk.Button cameraButton;

	[GtkChild]
	unowned Gtk.Revealer videoRevealer;
	
	[GtkChild]
	unowned Gtk.Box videoBox;
	
	[GtkChild]
	unowned Gtk.Label distanceLabel;
	
	[GtkChild]
	unowned Gtk.Entry ttsEntry;
	
	[GtkChild]
	unowned Gtk.Statusbar statusBar;
	
	private Gtk.Widget videoWidget;
	private Gst.Pipeline pipeline;
	private Pid ttsPid;
	private Soup.Session session;


	private float distance = 0.0f;

	private int qosCount = 0;
	private bool busMessaging = false;

	private string camURI = "rtsp://esp32cam.local/mjpeg/1";
	private string espURI = "http://192.168.226.10";

	public MainWindow(){
		session = new Soup.Session();

		//TODO: Change source to a real camera source
		var source = Gst.ElementFactory.make("rtspsrc", "source");
		var decodebin = Gst.ElementFactory.make("decodebin", "decodebin");
		var convert = Gst.ElementFactory.make("videoconvert", "convert");
		var gtksink = Gst.ElementFactory.make("gtksink", "gtksink");
		if(source == null || decodebin == null || convert == null || gtksink == null){
			error("Failed to create one or more GStreamer elements");
		}
		source.set_property("location", camURI);

		var val = GLib.Value(typeof(Gtk.Widget));
		gtksink.get_property("widget",ref val);
		videoWidget = (Gtk.Widget)val.get_object();
		videoBox.pack_start(videoWidget, true, true, 0);
		videoBox.reorder_child (videoWidget, 0);
		pipeline = new Gst.Pipeline ("pipeline");
		pipeline.add_many (source, decodebin, convert, gtksink);
		
		source.pad_added.connect ((src, srcPad) =>{
			var sinkPad = decodebin.get_static_pad ("sink");
			var srcCaps = srcPad.get_current_caps();
			message(@"Source pad for rtspsrc was added:\n$(srcCaps.to_string())");
			if(srcCaps != null && srcCaps.to_string().contains("application/x-rtp")){
				if(!sinkPad.is_linked()){
					var resp = srcPad.link(sinkPad);
					message("Source pad linked: %s", resp.to_string());
				}
				else{
					message("Source pad is already linked to decodebin");
				}
			}
		});

		decodebin.pad_added.connect ((dbin, dbinPad)=>{
			var sinkPad = convert.get_static_pad("sink");
			var dbinCaps = dbinPad.get_current_caps();
			message(@"Decodebin pad was added:\n$(dbinCaps.to_string())");
			if (dbinCaps != null && dbinCaps.to_string().contains("video")) {
				cameraButton.set_sensitive(true);
				statusBar.push(0, "Stream is ready");
				int width = 0, height = 0;
				weak Gst.Structure structure = dbinCaps.get_structure(0);
				if (structure != null) {
					structure.get_int("width", out width);
					structure.get_int("height", out height);
					message("Video dimensions: %d x %d", width, height);
					videoWidget.set_size_request(width, height);
				}
				else {
					message("No video structure found in caps");
				}

				if (!sinkPad.is_linked()) {
					dbinPad.link(sinkPad);
					message("Decodebin pad linked to convert: %s", dbinCaps.to_string());
				} 
				else {
					message("Decodebin pad is already linked to convert");
        		}
    		}
		});

		if(!convert.link(gtksink)){
			warning("couldn't link");
		}

		pipeline.set_state (Gst.State.PLAYING);
		//Debugging stuff --------------------------------
		if(busMessaging){
			var bus = pipeline.get_bus();
			bus.add_signal_watch();
			bus.message.connect ((bus, msg) =>{
				switch (msg.type){
					case Gst.MessageType.QOS:
					qosCount++;
					if (qosCount % 100 == 0) {
						message("QOS message received: %d", qosCount);
					}
					break;
					case Gst.MessageType.ELEMENT:
					message("Element specific message from: %s\nCountens: %s", msg.src.get_name(), msg.get_structure().to_string());
					break;
					default:
					message("Bus message recieved: %s", msg.type.to_string());
					break;
				}		
			});
		}
		//------------------------------------------------
		cameraButton.set_sensitive (false);
		statusBar.push (0, "Initializing stream...");
		videoWidget.show();

		Timeout.add(500, () => {
			var reqMessage = new Soup.Message ("GET", @"$espURI/distance");
			session.send_and_read_async.begin (reqMessage,Priority.DEFAULT, null, (obj, res) => {
				try {
					var resp = session.send_and_read_async.end (res);
					message("Response: %s", (string)resp);
					if (float.try_parse((string)resp, out distance)) {
						distanceLabel.set_text (@"Distance: $distance cm");
					} else {
						warning("Failed to parse distance from response: %s", (string)resp);
						distanceLabel.set_text ("Distance: N/A");
					}
				} catch (Error e) {
					warning("Failed to send GET request: %s", e.message);
					distanceLabel.set_text ("Distance: Error");
				}
			});
			return true; // Keep the timeout active
		});


	}

	[GtkCallback]
	private void unlockDoor (Gtk.Button button) {
		message ("Unlocking door");
		statusBar.push (0, "Unlocking door...");
		var multipart = new Soup.Multipart("multipart/form-data");
		multipart.append_form_string ("command", "unlock");
		var postMessage = new Soup.Message.from_multipart (espURI, multipart);
		session.send_and_read_async.begin(postMessage, Priority.DEFAULT, null, (obj, res) =>{
			try {
				var resp = session.send_and_read_async.end (res);
				message("Response: %s", (string)resp);
				statusBar.push(0, "Unlocked door successfully");
			} catch (Error e) {
				warning("Failed to send POST request: %s", e.message);
				statusBar.push(0, "Failed to unlock door");
				return;
			}
		});
	}
	[GtkCallback]
	private void openCamera (Gtk.Button button) {
		if(videoRevealer.reveal_child){
			videoRevealer.reveal_child = false;
			pipeline.set_state (Gst.State.PAUSED);
			message ("Closing camera");
			statusBar.push (0, "Closing camera...");

		}
		else{
			videoRevealer.reveal_child = true;
			pipeline.set_state (Gst.State.PLAYING);
			message ("Opening camera");
			statusBar.push (0, "Opening camera...");
		}
		button.label = videoRevealer.reveal_child ? "🞃 Close Camera" : "🞂 Open Camera";
		
	}

	[GtkCallback]
	private void sendTTSMessage (Gtk.Button button) {
		message ("Sending TTS message: %s\n", ttsEntry.text);
		string[] spawnArgs = { "src/tts", ttsEntry.text };
		try{
			Process.spawn_async (null, spawnArgs, null, SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD, null, out ttsPid);
			message("Generating TTS message");
			statusBar.push (0, "Generating TTS message...");
			ChildWatch.add (ttsPid, (pid, status) => {
				message ("TTS process finished");
				statusBar.push (0, "TTS message was generated successfully");
				Process.close_pid (pid);
				SendTTSPost();
			});
		}
		catch(Error e) {
			warning ("Failed to spawn piper process: %s", e.message);
			statusBar.push (0, "Failed to send TTS message");
		}
	}

	[GtkCallback]
	private void entry_changed (Gtk.Editable editable) {
		message ("Entry changed, text: %s\n", ttsEntry.text);
		notify_property ("ttsText");
	}

	void SendTTSPost() {
		// Read the audio file into a GLib.Bytes
		GLib.Bytes audioBytes;
		try {
			audioBytes = GLib.File.new_for_path ("src/tmp/tts.wav").load_bytes();
		} catch (Error e) {
			warning("Failed to read audio file: %s", e.message);
			statusBar.push(0, "Failed to read audio file");
			return;
		}

		var multipart = new Soup.Multipart("multipart/form-data");
		multipart.append_form_string ("command", "tts");
		multipart.append_form_file ("audio", "src/tmp/tts.eav", "audio/wav",audioBytes);
		var postMessage = new Soup.Message.from_multipart (espURI, multipart);
		session.send_and_read_async.begin (postMessage, Priority.DEFAULT, null, (obj, res) =>{
			try{
				var resp = session.send_and_read_async.end (res);
				message("Response: %s", (string)resp);
				statusBar.push(0, "Audio file sent successfully");
			}
			catch (Error e) {
				warning("Failed to send POST request: %s", e.message);
				statusBar.push(0, "Failed to send audio file");
			}
		});
	}
}

public void main (string[] args) {
	Gtk.init (ref args);
	Gst.init (ref args);

	var app = new MainWindow ();
	app.show_all ();

	Gtk.main();
}