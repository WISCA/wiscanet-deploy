function normVec = normData(vec)

    %# get max and min
    maxVec = max(vec);	   
    minVec = min(vec);

    %# normalize to -1...1	
    normVec = ((vec-minVec)./(maxVec-minVec) - 0.5 ) * 2;

end