function h = hmat(svmat,usrpos)
% Input parameters:
% svmat: Satellite coordinate matrix in the user-defined rectangular coordinate system
% usrpos: User's position in the user-defined rectangular coordinate system
% Output parameter:
% h: Direction cosine matrix for GPS positioning

N = max(size(svmat));
if N < 4,
    error('insufficient number of satellites')
else
    tmppos = usrpos;
    [m,n] = size(tmppos);
    if m > n, tmppos = tmppos'; end,
    h = ones(N,4);
    % linear expansion in user position, the precision depends on the user coordinates
    for i = 1:N,
        tmpvec = tmppos - svmat(i,:);
        h(i,1:3) = tmpvec./norm(tmpvec);
    end,
end,
