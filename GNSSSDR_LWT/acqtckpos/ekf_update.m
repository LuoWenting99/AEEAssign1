function [state_ekf, cov_ekf] = ekf_update(prvec, doppler_mps, svxyzr, sv_vel, sv_clk_vel, state_ekf, cov_ekf, Q_ekf, R_ekf, dt)
% EKF Update Steps: Use pseudorange and Doppler measurements to estimate the user state (position, velocity, clock bias, and clock drift).

num_sv = length(prvec);
H = zeros(2*num_sv, 8);  % Observation matrix
Z = zeros(2*num_sv, 1);  % Measurement residual

% --- State Transition Matrix (F) ---
F = eye(8);
F(1:3, 4:6) = eye(3) * dt;  %Position and velocity relationship
F(7, 8) = dt;               % Clock bias and clock drift relationship

% --- State prediction ---
state_pred = F * state_ekf;
cov_pred = F * cov_ekf * F' + Q_ekf;

% --- Observation model construction---
pos_pred = state_pred(1:3);
vel_pred = state_pred(4:6);
clk_bias_pred = state_pred(7);
clk_drift_pred = state_pred(8);

for i = 1:num_sv
    sv_pos = svxyzr(i, :)';
    sv_vel_i = sv_vel(i, :)';
    
    % Geometric distance and unit vector
    delta_pos = sv_pos - pos_pred;
    dist = norm(delta_pos);
    unit_vec = delta_pos / dist;
    
    % Relative velocity projection
    delta_vel = sv_vel_i - vel_pred;
    rate = dot(delta_vel, unit_vec) - sv_clk_vel(i) + clk_drift_pred;
    
    % Pseudorange residual (including clock bias)
    Z(i) = prvec(i) - (dist + clk_bias_pred);
    H(i, 1:3) = -unit_vec';  % Position partial derivative
    H(i, 7) = 1;             % Clock bias partial derivative
    
    % Doppler residual (including clock drift)
    Z(num_sv + i) = doppler_mps(i) - rate;
    H(num_sv + i, 4:6) = -unit_vec';  % Velocity partial derivative
    H(num_sv + i, 8) = 1;             % Clock drift partial derivative
end

% --- Kalman gain calculation ---
K = cov_pred * H' / (H * cov_pred * H' + R_ekf);

% ---State update ---
innov = Z - H * state_pred;
state_ekf = state_pred + K * innov;
cov_ekf = (eye(8) - K * H) * cov_pred;

end