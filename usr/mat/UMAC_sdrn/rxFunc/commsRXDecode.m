function decodeBits = commsRXDecode(msgBits, objDeinter)
       
   % Deinterleave bits
   decodeBits = step(objDeinter, msgBits);

end


