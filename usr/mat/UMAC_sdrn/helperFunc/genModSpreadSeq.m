function modSpreadSeq = genModSpreadSeq(spreadVal, index, modObj)
    
    % 
    hKasamiSeq = comm.KasamiSequence(...
                    'SamplesPerFrame', spreadVal, ...
                    'Index', index);
            
    % Generate spreading sequence
    spreadSeq = step(hKasamiSeq);
    
    % Modulate spreading sequence
    modSpreadSeq = step(modObj, spreadSeq);
     
    % Release object
    releaseObjs(hKasamiSeq);

end