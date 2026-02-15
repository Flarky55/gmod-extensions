local Compress, Decompress = util.Compress, util.Decompress
local WriteUInt, ReadUInt, WriteData, ReadData = net.WriteUInt, net.ReadUInt, net.WriteData, net.ReadData

local BITS_DATA_LENGTH = 16


local function WriteDataEasy( binaryData )
    local length = #binaryData

    WriteUInt( length, BITS_DATA_LENGTH )
    WriteData( binaryData )
end
net.WriteDataEasy = WriteDataEasy

local function ReadDataEasy()
    return ReadData( ReadUInt( BITS_DATA_LENGTH ) )
end
net.ReadDataEasy = ReadDataEasy

function net.WriteCompressedData( str )
    WriteDataEasy( Compress( str ) )
end

net.ReadCompressedData = ReadDataEasy