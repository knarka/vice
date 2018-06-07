class Vice::Blitter
	def initialize(window)
		Curses.init_pair 1, Curses::COLOR_BLACK, Curses::COLOR_WHITE
		window.attrset Curses.color_pair(0)
	end

	def drawtabs(vice, buffer, window)
		window.setpos 0, 0
		window.addstr ' ' * Curses.cols
		window.setpos 0, 3
		vice.buffers.each do |b|
			name = b.filename || '[no name]'
			name = b == buffer ? '>' + name + '<' : name
			name = b.modified ? '+ ' + name : name

			window.addstr name + ' | '
		end
	end

	def drawalert(vice, window)
		window.setpos Curses.lines - 1, 0
		window.addstr ' ' * Curses.cols

		return if vice.msg.nil?

		window.setpos Curses.lines - 1, 0
		window.addstr vice.msg

		vice.reset_alert
	end

	def drawstatus(mode, window, buffer, prompt)
		window.attrset Curses.color_pair(1)

		# clear
		window.setpos Curses.lines - 2, 0
		window.addstr ' ' * Curses.cols

		# draw mode
		window.setpos Curses.lines - 2, 0
		modestring = if mode == :insert
				     ' -- insert --'
			     elsif mode == :prompt
				     ' :' + prompt
			     end
		window.addstr modestring

		# draw cursor position
		location = buffer.cursor.line.to_s + ',' + buffer.cursor.col.to_s
		window.setpos Curses.lines - 2, Curses.cols - location.length - 1
		window.addstr location

		window.attrset Curses.color_pair(0)
	end

	def formatnumber(number)
		delta = if number == '~'
				@linenumwidth - 1
			else
				@linenumwidth - number.to_s.length
			end
		delta.times do
			number = ' ' + number.to_s
		end
		number += ' '
	end

	def pad(string)
		delta = Curses.cols - string.length
		delta.times { string += ' ' } if delta > 0
		string
	end

	def drawbuffer(vice, window)
		buffer = vice.buffers[vice.current_buffer]
		visual_cursor = Vice::Cursor.new buffer.cursor.line, 0

		(0..buffer.cursor.col - 1).each do |i|
			visual_cursor.col += if buffer.currentline[i] == "\t"
						     Vice::TAB_WIDTH
					     else
						     1
					     end
		end

		drawtabs vice, buffer, window

		@linenumwidth = buffer.lines.to_s.length + 1
		(1..Curses.lines - 2).each do |r|
			i = r - 1
			window.setpos r, 0
			if i < buffer.lines
				line = pad buffer.getline(i).gsub(/(\t)/, ' ' * Vice::TAB_WIDTH)
				window.addstr formatnumber(i + 1) + line
			else
				window.addstr pad(formatnumber('~'))
			end
		end

		drawstatus vice.mode, window, buffer, vice.prompt

		drawalert vice, window

		visual_cursor.line += 1 # space for tabs above buffer
		visual_cursor.col += @linenumwidth + 1	# leave space for line numbers

		if vice.mode == :prompt
			window.setpos Curses.lines - 2, vice.prompt.length + 2
		else
			window.setpos visual_cursor.line, visual_cursor.col
		end
		window.refresh
	end
end
