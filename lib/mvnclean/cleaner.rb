require 'time'

module MavenClean

	class Cleaner

		def initialize()
			@repo = get_default_repo
			@ignore_folders = [ '.', '..' ]
			dt = DateTime.now << 6
			@date_threshold = dt.to_time
			@candidates = []
			@candidates_size = 0
		end

		def clean()
			if( File.exist?( @repo ) )
				puts "Cleaning dependencies older than #{@date_threshold} from repository #{@repo}..."
				scan
				puts "Found #{@candidates.size} candidates totalling #{approx_size(@candidates_size)}"
			else
				puts "Can't find repo: #{@repo}"
			end
		end

		private

		# Get the Default Repository
		def get_default_repo
			ENV[ "M2_REPO" ] || File.join( Dir.home, ".m2", "repository" )
		end   

		# Search for POM files
		def scan( dirname = nil )
			dir_path = get_repo_abs_path( dirname )
			Dir.foreach( dir_path ) do |child|
				child_abs_path = File.join( dir_path, child )
				if File.directory?( child_abs_path ) then
					child_rel_path = get_repo_rel_path( dirname, child )
					scan child_rel_path unless @ignore_folders.include? child
				else
					select_candidates( dirname ) if File.extname( child ) == '.pom'
				end
			end
		end

		def get_repo_abs_path( dirname )
			if dirname == nil then
				@repo
			else
				File.join( @repo, dirname )
			end
		end

		def get_repo_rel_path( dirname, child )
			if dirname == nil then
				child
			else
				File.join( dirname, child )
			end
		end

		# Consider a Project (as identified by its POM) for Deletion
		def select_candidates( folder )
			mru = get_mru( folder )
			if mru < @date_threshold then
				@candidates << folder
				fs = folder_size( folder )
				@candidates_size += fs
				puts "- #{folder} (#{approx_size(fs)})"
			end
		end

		def folder_size( dirname )
			path = get_repo_abs_path( dirname )
			paths = Dir.entries( path ).map { |f| File.join path, f }
			files = paths.select{ |x| File.file? x }
			sizes = files.map{ |x| File.size( x ) }
			sizes.reduce :+
		end

		# Get the access time of the most recently used file within the directory.
		def get_mru( dirname )
			mru = nil
			dir_path = File.join( @repo, dirname )
			Dir.foreach( dir_path ) do |child|
				child_path = File.join( dir_path, child )
				if File.file? child_path then
					atime = File.atime( child_path )
					mru = atime if mru == nil || atime > mru
				end
			end
			return mru
		end

		def approx_size( size )
			units = ['PB', 'TB', 'GB', 'MB', 'KB', 'B']
			magnitude = size
			unit = units.pop

			while magnitude > 1000 do
				magnitude /= 1000
				unit = units.pop
			end

			"~#{magnitude}#{unit}"
		end

	end

end