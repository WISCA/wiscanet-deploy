function releaseObjs(varargin)

    nArgs = length(varargin);
    
    for n = 1:nArgs
        
        release(varargin{n});
        
    end

end