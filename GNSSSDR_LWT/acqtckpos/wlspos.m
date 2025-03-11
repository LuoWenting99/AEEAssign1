function [estusr, dop] = wlspos(prvec, svxyzmat, initpos, tol, weight)
%WLSPOS Compute position using Weighted Least Squares.
%
% [estusr, dop] = wlspos(prvec, svxyzmat, initpos, tol, weight)
%
% INPUTS:
%   prvec    : Pseudorange measurements.
%   svxyzmat : Satellite positions (Nx3 matrix).
%   initpos  : Initial user state [x,y,z,clock_offset] (optional).
%   tol      : Convergence tolerance (optional, default=1e-3).
%   weight   : Weight vector (optional, default=ones). Each element is the inverse variance of measurement.
%
% OUTPUTS:
%   estusr   : Estimated user state [x,y,z,clock_offset].
%   dop      : Dilution of precision metrics [GDOP, PDOP, HDOP, VDOP].

% parameter processing 
if nargin < 5, weight = ones(size(prvec)); end
if nargin < 4, tol = 1e-3; end
if nargin < 3, initpos = [0 0 0 0]; end

% Initialize user state
[m, n] = size(initpos);
if m > n, estusr = initpos'; else, estusr = initpos; end
if max(size(estusr)) < 3
    error('initpos must have at least 3 dimensions.');
end
if max(size(estusr)) < 4
    estusr = [estusr 0];
end

% Check if the weights and pseudorange lengths match
numvis = length(prvec);
if length(weight) ~= numvis
    error('Weight vector must match the number of satellites.');
end

beta = [1e9 1e9 1e9 1e9];
maxiter = 10;
iter = 0;

while iter < maxiter && norm(beta) > tol
    % Calculate pseudorange residuals
    y = zeros(numvis, 1);
    for N = 1:numvis
        pr0 = norm(svxyzmat(N, :) - estusr(1:3));
        y(N) = prvec(N) - pr0 - estusr(4);
    end
    
    H = hmat(svxyzmat, estusr(1:3)); % Geometric matrix
    W = diag(weight);                 % Weight matrix
    
    % WLS solution
%     beta = (H' * W * H) \ (H' * W * y);
    beta = (H' * W * H + 1e-6 * eye(4)) \ (H' * W * y); 
    estusr = estusr + beta';
    iter = iter + 1;
end

% Calculate DOP
% Q = inv(H' * W * H);
Q = pinv(H' * W * H);
dop = zeros(1, 4);
dop(1) = sqrt(trace(Q));              % GDOP
dop(2) = sqrt(Q(1,1) + Q(2,2) + Q(3,3)); % PDOP
dop(3) = sqrt(Q(1,1) + Q(2,2));       % HDOP
dop(4) = sqrt(Q(3,3));                % VDOP

end

% Auxiliary function hmat
function H = hmat(svxyz, estpos)
num_sv = size(svxyz, 1);
H = zeros(num_sv, 4);
for i = 1:num_sv
    rho = norm(svxyz(i, :) - estpos);
    H(i, 1:3) = (estpos - svxyz(i, :)) / rho;
    H(i, 4) = 1;
end
end