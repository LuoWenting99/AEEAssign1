function plotCorrelation(TckResult_Eph, svList)
    figure;
    colors = lines(length(svList)); % Assign a different color to each satellite
    hold on;
    legend_handles = []; % Store the first line handle for each satellite
    
    for svIdx = 1:length(svList)
        sv = svList(svIdx);
        % Extract the current satellite's I/Q data   
        E_i = TckResult_Eph(sv).E_i;
        E_q = TckResult_Eph(sv).E_q;
        E4_i = TckResult_Eph(sv).E4_i;
        E4_q = TckResult_Eph(sv).E4_q;        
        E3_i = TckResult_Eph(sv).E3_i;
        E3_q = TckResult_Eph(sv).E3_q;
        E2_i = TckResult_Eph(sv).E2_i;
        E2_q = TckResult_Eph(sv).E2_q;
        E1_i = TckResult_Eph(sv).E1_i;
        E1_q = TckResult_Eph(sv).E1_q;
        P_i = TckResult_Eph(sv).P_i;
        P_q = TckResult_Eph(sv).P_q;
        L1_i = TckResult_Eph(sv).L1_i;
        L1_q = TckResult_Eph(sv).L1_q;  
        L2_i = TckResult_Eph(sv).L2_i;
        L2_q = TckResult_Eph(sv).L2_q;
        L3_i = TckResult_Eph(sv).L3_i;
        L3_q = TckResult_Eph(sv).L3_q;
        L4_i = TckResult_Eph(sv).L4_i;
        L4_q = TckResult_Eph(sv).L4_q;
        L_i = TckResult_Eph(sv).L_i;
        L_q = TckResult_Eph(sv).L_q;
        
        % Calculate the magnitude
        E = sqrt(E_i.^2 + E_q.^2);
        E4 = sqrt(E4_i.^2 + E4_q.^2);
        E3 = sqrt(E3_i.^2 + E3_q.^2);
        E2 = sqrt(E2_i.^2 + E2_q.^2);
        E1 = sqrt(E1_i.^2 + E1_q.^2);
        P   = sqrt(P_i.^2 + P_q.^2);
        L1  = sqrt(L1_i.^2 + L1_q.^2);
        L2  = sqrt(L2_i.^2 + L2_q.^2);
        L3  = sqrt(L3_i.^2 + L3_q.^2);
        L4  = sqrt(L4_i.^2 + L4_q.^2);
        L  = sqrt(L_i.^2 + L_q.^2);
        
        %Mark if it is the first line for this satellite
        is_first_plot = true; 
        
        %Plot the line
        numPoints = length(E);
        for idx = 1000:1000:numPoints
            if idx > numPoints
                break;
            end
            x = [-0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5]; 
            y = [E(idx), E4(idx), E3(idx), E2(idx), E1(idx), P(idx), L1(idx), L2(idx), L3(idx), L4(idx), L(idx)];
            
            if is_first_plot
                % Record the first line handle and add to the legend
                h = plot(x, y, 'Color', colors(svIdx, :), 'LineWidth', 0.5);
                legend_handles = [legend_handles, h];
                is_first_plot = false;
            else
                % Do not add the legend for subsequent lines
                plot(x, y, 'Color', colors(svIdx, :), 'LineWidth', 0.5);
            end
        end
    end
    
    hold off;
    xlabel('Time Delay (Chip)');
    ylabel('Correlation Value');
    title('OpenSky Correlation Plot');
    
    % Set the legend (each satellite corresponds to a color)
    legend(legend_handles, arrayfun(@(x) sprintf('SV %d', x), svList, 'UniformOutput', false));
    grid on;
end