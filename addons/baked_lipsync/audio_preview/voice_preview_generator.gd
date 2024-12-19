@tool
extends Node

signal texture_ready(texture)
signal generation_progress(normalized_progress)

const MAX_FREQUENCY: float = 3000.0 # Maximum frequency captured
const IMAGE_HEIGHT: int = 64

var image_compression: float = 10.0 # How many samples in one pixel
var background_color = Color(0.2, 0.2, 0.4, 0.5)
var foreground_color = Color.SILVER




# =============================================================================


const SAMPLING_RATE = 2.0*MAX_FREQUENCY
const IMAGE_HEIGHT_FACTOR: float = float(IMAGE_HEIGHT) / 256.0 # Converts sample raw height to pixel
const IMAGE_CENTER_Y = int(round(IMAGE_HEIGHT / 2.0))

var is_working := false
var must_abort := false


func generate_preview(stream: AudioStreamWAV, image_max_width: int = 500):
	if not stream:
		return
	
	if stream.format == AudioStreamWAV.FORMAT_IMA_ADPCM:
		return # not supported
	
	if image_max_width <= 0:
		return # User wasn't remarkably brilliant
	
	if is_working:
		must_abort = true
		while is_working:
			await get_tree().process_frame
	
	is_working = true
	
	var data = stream.data
	var data_size = data.size()
	var is_16bit = (stream.format == AudioStreamWAV.FORMAT_16_BITS)
	var is_stereo = stream.stereo
	
	
	
	# For display reasons, lower frequencies than the sampling rate might suffice. 
	# According to the gentlemen of noble steem known as Nyquist and Shannon, 
	# we can sample at SAMPLING_RATE
	
	
	var sample_interval = 1
	if stream.mix_rate > SAMPLING_RATE:
		sample_interval = int(round(stream.mix_rate / SAMPLING_RATE))
	if is_16bit:
		sample_interval *= 2
	if is_stereo:
		sample_interval *= 2
	
	var reduced_data = PackedByteArray()
	# We use floor(), not round(), because extra elements in the end of data
	# before next sampling interval are discarded
	var reduced_data_size = int(floor( data_size / float(sample_interval) ))
	reduced_data.resize(reduced_data_size)
	
	
	# For drawing a preview, we use only one byte left channel per sample
	# PCM16 is little endian, so MSB is index 1, not 0
	# reduced_data will contain only that one byte per sample
	var sample_in_i := 1 if is_16bit else 0
	var sample_out_i := 0
	while (sample_in_i < data_size) and (sample_out_i < reduced_data_size):
		reduced_data[sample_out_i] = data[sample_in_i]
		
		sample_in_i += sample_interval
		sample_out_i += 1
		
		if must_abort:
			is_working = false
			must_abort = false
			return
	
	
	# From now on we work only with reduced_data 
	
	image_compression = ceil(reduced_data_size / float(image_max_width))
	
	var img_width = floor(reduced_data_size/image_compression) # Again floor as we discard remaining samples
	var img = Image.create(img_width, IMAGE_HEIGHT, true, Image.FORMAT_RGBA8)
	img.fill(Color.DARK_SLATE_GRAY)
	
	var sample_i = 0
	var img_x = 0
	var final_sample_i = (reduced_data_size - image_compression)
	while sample_i < final_sample_i:
		var min_val := 128
		var max_val := 128
		for block_i in range(image_compression):
			var sample_val = reduced_data[sample_i]
			# Convert signed bytes to unsigned bytes
			sample_val += 128
			if sample_val >= 256:
				sample_val -= 256
			
			# Get minmax
			if sample_val < min_val:
				min_val = sample_val
			if sample_val > max_val:
				max_val = sample_val
			
			
			sample_i += 1
		
		
		# Center pixel is always drawn
		if (min_val == 128) and (max_val == 128):
			img.set_pixel(img_x, IMAGE_CENTER_Y, foreground_color)
		
		else:
			var min_height = int(clamp(
				floor(IMAGE_HEIGHT - (min_val*IMAGE_HEIGHT_FACTOR)),
				0, IMAGE_HEIGHT-1
			))
			var max_height = int(clamp(
				floor(IMAGE_HEIGHT - (max_val*IMAGE_HEIGHT_FACTOR)),
				0, IMAGE_HEIGHT-1
			
			))
			
			# min_height and max_height are in audio sample direction (positive up)
			# while img_y is in image direction (positive down)
			var img_y = max_height # top value is lower img_y
			while img_y <= min_height: # bottom value is higher img_y
				img.set_pixel(img_x, img_y, foreground_color)
				img_y += 1
		
		img_x += 1
		
		if must_abort:
			is_working = false
			must_abort = false
			return

		if (sample_i % 100) == 0:
			var progress = sample_i / final_sample_i
			emit_signal("generation_progress", progress)
			await get_tree().process_frame
	
	is_working = false
	
	emit_signal("texture_ready", ImageTexture.create_from_image(img))
	
