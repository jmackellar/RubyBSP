# Procedural BSP 
# Generated layout saved to outputX.txt 

# Tree Class
# Holds Data for the base area size and root node
# of the generated BSP Trees.  The leaves of the 
# tree are assumed to be balanced, every child should
# have a paired sibling.
class Tree 
	def initialize(args)
		@areaWidth, @areaHeight, @divisionsToMake = *args
		@rootNode = Node.new([0, 0, @areaWidth, @areaHeight, @divisionsToMake, 1])
	end

	def displayTree(renderTarget)
		return @rootNode.displayNode(renderTarget)
	end
end

# Node Class
# Holds data for a subdivided area, individiual rooms, and
# their connections in a BSP Tree
class Node
	def initialize(args)
		@areaX, @areaY, @areaWidth, @areaHeight, @divisionsToMake, @currentDivision, @parentNode = *args 
		@roomConnectors = [ ]
		# Subdivide nodes until we reach max divisions then 
		# place rooms in the bottom nodes
		if @currentDivision < @divisionsToMake
			self.divideNode()
		else 
			self.createRoom()
		end
	end

	# Renders display of rooms and connectors of self and all
	# child nodes to the passed renderTarget 2D array
	def displayNode(renderTarget)
		renderTarget = self.displayRoom(renderTarget)
		renderTarget = self.displayConnectors(renderTarget)
		if @children
			renderTarget = @children[0].displayNode(renderTarget)
			renderTarget = @children[1].displayNode(renderTarget)
		end
		return renderTarget
	end

	# Displays connections between rooms and nodes 
	# on the passed randerTargeT 2D array
	def displayConnectors(renderTarget)
		for i in 0 .. @roomConnectors.length() - 1
			xMin = [@roomConnectors[i][0], @roomConnectors[i][2]].min
			xMax = [@roomConnectors[i][0], @roomConnectors[i][2]].max
			yMin = [@roomConnectors[i][1], @roomConnectors[i][3]].min
			yMax = [@roomConnectors[i][1], @roomConnectors[i][3]].max
			for x in xMin .. xMax
				renderTarget[x][@roomConnectors[i][1]] = '.'
			end 
			for y in yMin .. yMax
				renderTarget[@roomConnectors[i][2]][y] = '.'
			end
		end
		return renderTarget
	end

	# Displays the area of the created room on the passed
	# renderTarget 2D array
	def displayRoom(renderTarget)
		if @room 
			for x in @room[0] .. @room[0] + @room[2]
				for y in @room[1] .. @room[1] + @room[3]
					renderTarget[x-1][y-1] = '.'
				end 
			end
		end
		return renderTarget
	end

	# Places a connection between the two child nodes
	# This connects the childs connectors to a connector
	# in the root node.
	def createRootConnector(childX1, childY1, childX2, childY2)
		@roomConnectors.push([childX1, childY1, childX2, childY2])
	end

	# Places a connection between the current node and 
	# one of its children's connector node.  Used for nodes
	# in the middle of the tree.
	def createConnectorToChild(childX, childY)
		@roomConnectors.push([
			(@areaX + @areaWidth / 2).floor,
			(@areaY + @areaHeight / 2).floor,
			childX, 
			childY
			])
	end

	# Places a connection between two rooms of the current
	# nodes children.  Used for nodes on the bottom of the tree.
	def createConnectorBetweenChildren()
		midX1, midY1 = @children[0].getRoomMidPoint()
		midX2, midY2 = @children[1].getRoomMidPoint()
		if midX1 and midY1 and midX2 and midY2 
			@roomConnectors.push([midX1, midY1, midX2, midY2])
		end
	end

	# Creates the room definition, used for nodes that sit 
	# on the bottom of the tree.
	def createRoom()
		width = rand(@areaWidth * 0.5 .. @areaWidth * 0.7).floor
		height = rand(@areaHeight * 0.5 .. @areaHeight * 0.7).floor
		@room = [
			rand(@areaX + @areaWidth * 0.15 .. @areaX + @areaWidth - width * 1.15).ceil,
			rand(@areaY + @areaHeight * 0.15 .. @areaY + @areaHeight - height * 1.15).ceil,
			width,
			height,
		]
	end

	# Passes a reference of the current nodes sibling
	def assignSiblingNode(sibling)
		@siblingNode = sibling 
	end

	# Divides the current node in half, either vertically or horizontally.
	def divideNode()
		# Choose a position along the perimeter to divide the node area by
		@chosenDivision = @areaWidth > @areaHeight ? 0 : 1
		divisionTypes = [
			rand(@areaX + (@areaWidth * 0.35).floor .. @areaX + @areaWidth - (@areaWidth * 0.35).ceil), 
			rand(@areaY + (@areaHeight * 0.35).floor .. @areaY + @areaHeight - (@areaHeight * 0.35).ceil),
		]
		possibleDivisions = [ 
			# Divide the area vertically
			[
				# First child node
				@areaX,
				@areaY,
				@areaX + @areaWidth - divisionTypes[@chosenDivision],
				@areaHeight,
				# Second child node 
				divisionTypes[@chosenDivision],
				@areaY,
				@areaX + @areaWidth - divisionTypes[@chosenDivision],
				@areaHeight,
				],
			# Divide the area horizontally
			[
				# First child Node
				@areaX,
				@areaY,
				@areaWidth,
				@areaY + @areaHeight - divisionTypes[@chosenDivision],
				# Second child node
				@areaX,
				divisionTypes[@chosenDivision],
				@areaWidth,
				@areaY + @areaHeight - divisionTypes[@chosenDivision],
				]
		]
		@areaDivision = possibleDivisions[@chosenDivision]
		# Create the child nodes and assign each other
		# a refernce to their sibling
		@children = [ 
			Node.new([
				@areaDivision[0], 
				@areaDivision[1], 
				@areaDivision[2], 
				@areaDivision[3], 
				@divisionsToMake, 
				@currentDivision + 1, 
				self
				]),
			Node.new([
				@areaDivision[4], 
				@areaDivision[5], 
				@areaDivision[6], 
				@areaDivision[7], 
				@divisionsToMake, 
				@currentDivision + 1, 
				self
				]),
			]
		@children[0].assignSiblingNode(@children[1])
		@children[1].assignSiblingNode(@children[0])
		# Create connections between sibling, parent, and child nodes
		self.createConnectorBetweenChildren()
		if @parentNode 
			@parentNode.createConnectorToChild(@roomConnectors[0][0], @roomConnectors[0][1])
		else
			x1, y1 = @children[0].getConnectorStart()
			x2, y2 = @children[0].getConnectorStart()
			self.createRootConnector(x1, y1, x2, y2)
		end
	end

	# Returns the mid point of a room.  Used to connect rooms together for
	# nodes on the bottom of the tree
	def getRoomMidPoint()
		if @room 
			return (@room[0] + @room[2] / 2).floor, (@room[1] + @room[3] / 2).floor
		else
			return false 
		end
	end

	# Returns where a nodes given first connector starts.  Used to connect
	# nodes together by connecting to a previous connector instead of
	# a room
	def getConnectorStart()
		if @roomConnectors.length() > 0
			return @roomConnectors[0][0], @roomConnectors[0][1]
		else
			return false
		end
	end
end

# Run test of BSP generation, saving the results to 
# the local folder
def runTest()
	areaWidth = rand(80..140)
	areaHeight = rand(40..80)
	subdivisions = rand(3..6)
	bspTree = Tree.new([areaWidth, areaHeight, subdivisions])
	createTextOutput(bspTree, areaWidth, areaHeight, subdivisions)
end

# Creates a 2D array to have the BSP Tree rooms drawn to
def createTextOutput(tree, width, height, divisions)
	areaMap = [ ]
	textOutput = [ ]
	for x in 0..width 
		areaMap[x] = [ ]
		for y in 0..height 
			areaMap[x][y] = '#'
		end
	end
	areaMap = tree.displayTree(areaMap)
	saveTextOutput(1, areaMap, width, height, divisions)
end

# Save the generated BSP Tree to file OutputX.txt
def saveTextOutput(iter, tosave, width, height, divisions)
	fileName = "output" + iter.to_s + ".txt"
	if not File.exists?(fileName) 
		saveText = 'Generated area of size ' + width.to_s + ' x ' + height.to_s + ' with ' + divisions.to_s + " divisions.\n"
		saveFile = File.new(fileName, "w")
		for y in 0..height 
			for x in 0..width 
				saveText = saveText + tosave[x][y]
			end 
			saveText = saveText + "\n"
		end
		saveFile.syswrite(saveText)
	else 
		saveTextOutput(iter + 1, tosave, width, height, divisions)
	end
end

runTest() 