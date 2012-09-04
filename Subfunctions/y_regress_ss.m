function [b,r,SSE,SSR, T] = y_regress_ss(y,X)
% [b,r,SSE,SSR, T] = y_regress_ss(y,X)
% Perform regression.
% Revised from MATLAB's regress in order to speed up the calculation.
% Input:
%   y - Independent variable.
%   X - Dependent variable.
% Output:
%   b - beta of regression model.
%   r - residual.
%   SSE - The sum of squares of error.
%   SSR - The sum of squares of regression.
%   T - T value for each beta.
%___________________________________________________________________________
% Written by YAN Chao-Gan 100317.
% State Key Laboratory of Cognitive Neuroscience and Learning, Beijing Normal University, China, 100875
% ycg.yan@gmail.com
% Revised by YAN Chao-Gan 120519. Also output T value for each beta. Referenced from regstats.m

[n,ncolX] = size(X);
[Q,R,perm] = qr(X,0);
p = sum(abs(diag(R)) > max(n,ncolX)*eps(R(1)));
if p < ncolX,
    R = R(1:p,1:p);
    Q = Q(:,1:p);
    perm = perm(1:p);
end
b = zeros(ncolX,1);
b(perm) = R \ (Q'*y);

if nargout >= 2
    yhat = X*b;                     % Predicted responses at each data point.
    r = y-yhat;                     % Residuals.
    if nargout >= 3
        SSE=sum(r.^2);
        if nargout >= 4
            SSR=sum((yhat-mean(y)).^2);
            
            if nargout >= 5
                %Also output T value for each beta. Referenced from regstats.m
                [Q,R] = qr(X,0);
                ri = R\eye(ncolX);
                T = b./sqrt(diag(ri*ri' * (SSE/(n-ncolX))));
            end
            
        end
    end
end
