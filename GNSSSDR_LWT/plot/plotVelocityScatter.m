function plotVelocityScatter(matFilePath,saveVelPath)
    % Load .mat file
    data = load(matFilePath);
    usrVel = data.navSolutionsCT.usrVelENU;
    localTime = data.navSolutionsCT.localTime;

    % extract velocity values
    usrVelX = usrVel(:, 1);
    usrVelY = usrVel(:, 2);

    % plot velocity scatter diagram
    figure;
    scatter(usrVelX, usrVelY, 40, localTime, 'filled');
%     blue = [0 0 1]
    blue = [linspace(0, 1, 256)' zeros(256, 1) ones(256, 1)]; 
    colormap(flipud(blue));  
    colorbar;
    xlabel('Predicted Velocity (X)');
    ylabel('Predicted Velocity (Y)');
    title('Velocity Prediction Results');
    grid on;

    % set the origin of the axes
    ax = gca;
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    legend('localtime')

    % save the image
    if nargin > 3 && ~isempty(saveVelPath)
        saveas(gcf, saveVelPath);
    end
end