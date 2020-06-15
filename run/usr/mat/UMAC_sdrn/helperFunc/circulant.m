function C = circulant(vec,lags)
%CIRCULANT Circulant Matrix.
%  CIRCULANT(V,LAGS) generates a square circulant matrix using the vector V
%  as the first row of the result if V is a row vector or as the first
%  column of the result if V is a column vector. V may be any numeric data
%  type or a character string.
%
%  LAGS is an optional input argument that describes the number of lags to
%  include in the matrix.
%
%  References:
%    http://en.wikipedia.org/wiki/Circulant_matrix
%    http://mathworld.wolfram.com/CirculantMatrix.html
%
% Example:
%  A backwards (-1) shift, result is a symmetric
%  matrix.
%
%  circulant([2 3 5 7 11 13],-1)
%
%  ans =
%       2     3     5     7    11    13
%       3     5     7    11    13     2
%       5     7    11    13     2     3
%       7    11    13     2     3     5
%      11    13     2     3     5     7
%      13     2     3     5     7    11
%
% Example:
%  A forwards (+1) shifted circulant matrix,
%  built using the first row defined by vec.
%
%  circulant([2 3 5 7 11],1)
%
%  ans =
%       2     3     5     7    11
%      11     2     3     5     7
%       7    11     2     3     5
%       5     7    11     2     3
%       3     5     7    11     2
%
% Example:
%  A postively shifted circulant matrix, built
%  from vec as the first column.
%
%  circulant([2;3;5;7;11],1)
%  ans =
%       2    11     7     5     3
%       3     2    11     7     5
%       5     3     2    11     7
%       7     5     3     2    11
%      11     7     5     3     2
%
% Example:
%  A negative shift applied to build a character
%  circulant matrix.
%  
%  circulant('abcdefghij',-1)
%
%  ans =
%  abcdefghij
%  bcdefghija
%  cdefghijab
%  defghijabc
%  efghijabcd
%  fghijabcde
%  ghijabcdef
%  hijabcdefg
%  ijabcdefgh
%  jabcdefghi
%
%  See also: toeplitz, hankel

    % error checks
    if (nargin<1) || (nargin > 2)
      error('circulant takes only one or two input arguments')
    end

    if (nargin < 2) || isempty(lags)
      lags = 1;
    end

    % verify that vec is a vector or a scalar
    if ~isvector(vec)
      error('vec must be a vector')
    elseif length(vec) == 1
      % vec was a scalar
      C = vec;
      return
    end

    % how long is vec?
    n = length(vec);

    if isrow(vec)
        C = vec(mod(bsxfun(@plus, lags', (1:n))-1,n)+1);
    else
        C = vec(mod(bsxfun(@plus, lags, (1:n)')-1,n)+1);
    end
  
end

