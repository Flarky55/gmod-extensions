local Compress, Decompress = util.Compress, util.Decompress
local WriteUInt, ReadUInt, WriteData, ReadData = net.WriteUInt, net.ReadUInt, net.WriteData, net.ReadData

local BITS_COMPRESSED_DATA_LENGTH = 16


function net.WriteCompressedData( str )
    local compressed = Compress( str )

    WriteUInt( #compressed, BITS_COMPRESSED_DATA_LENGTH )
    WriteData( compressed )
end

function net.ReadCompressedData()
    return Decompress( ReadData( ReadUInt( BITS_COMPRESSED_DATA_LENGTH ) ) )
end 