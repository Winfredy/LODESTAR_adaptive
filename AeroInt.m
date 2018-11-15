function [Cl_spline_EngineOff,Cd_spline_EngineOff,Cl_spline_EngineOn,Cd_spline_EngineOn,flap_spline_EngineOff,flap_spline_EngineOn,T_spline_Rear,Fd_spline_NoEngine,Cd_spline_ViscousEngineOff,Cd_spline_ViscousEngineOn,L_spline_Rear,T_spline] = AeroInt(aero,auxdata,T_L,CG_z)
% Sholto 2017
% This function calculates aerodynamic interpolation splines given inputs
% of aerodynamic data matrices.


aero_EngineOff = aero.aero_EngineOff;
aero_EngineOn = aero.aero_EngineOn;
aero_Engine = aero.aero_Engine;
flapaero = aero.flapaero;
Viscousaero_EngineOff = aero.Viscousaero_EngineOff;
Viscousaero_EngineOn = aero.Viscousaero_EngineOn;

%% Aerodynamic Data - Engine off

interp.flap_momentCl_scattered = scatteredInterpolant(flapaero(:,1),flapaero(:,5),flapaero(:,3), 'linear', 'nearest');
interp.flap_momentCd_scattered = scatteredInterpolant(flapaero(:,1),flapaero(:,5),flapaero(:,4), 'linear', 'nearest');
interp.flap_momentdef_scattered = scatteredInterpolant(flapaero(:,1),flapaero(:,5),flapaero(:,2), 'linear', 'nearest');

interp.Cl_scattered_EngineOff = scatteredInterpolant(aero_EngineOff(:,1),aero_EngineOff(:,2),aero_EngineOff(:,3));
interp.Cd_scattered_EngineOff = scatteredInterpolant(aero_EngineOff(:,1),aero_EngineOff(:,2),aero_EngineOff(:,4));
interp.Cm_scattered_EngineOff = scatteredInterpolant(aero_EngineOff(:,1),aero_EngineOff(:,2),aero_EngineOff(:,5));

interp.Cl_scattered_Viscousaero_EngineOff = scatteredInterpolant(Viscousaero_EngineOff(:,1),Viscousaero_EngineOff(:,2),Viscousaero_EngineOff(:,3)/1000,Viscousaero_EngineOff(:,4));
interp.Cd_scattered_Viscousaero_EngineOff = scatteredInterpolant(Viscousaero_EngineOff(:,1),Viscousaero_EngineOff(:,2),Viscousaero_EngineOff(:,3)/1000,Viscousaero_EngineOff(:,5));
    
MList_EngineOff = unique(aero_EngineOff(:,1));
% MList_EngineOff(end+1) = MList_EngineOff(end) + 1; % extrapolate for Mach no slightly

AoAList_engineOff = unique(aero_EngineOff(:,2));

altList_engineOff = unique(Viscousaero_EngineOff(:,3)); % Use engine only case for this

% [Mgrid_EngineOff,AOAgrid_EngineOff] = ndgrid(MList_EngineOff,AoAList_engineOff);

[Mgrid_EngineOff,AOAgrid_EngineOff,altgrid_EngineOff] = ndgrid(MList_EngineOff,AoAList_engineOff,altList_engineOff);

% Cl_Grid = reshape(aero(:,3),[length(unique(aero(:,2))),length(unique(aero(:,1)))]).';
% Cd_Grid = reshape(aero(:,4),[length(unique(aero(:,2))),length(unique(aero(:,1)))]).';

% 

Cl_Grid_EngineOff = [];
Cd_Grid_EngineOff = [];
Cm_Grid_EngineOff = [];
flap_Grid = [];


for i = 1:numel(Mgrid_EngineOff)
    M_temp = Mgrid_EngineOff(i);
    AoA_temp = AOAgrid_EngineOff(i);
    alt_temp = altgrid_EngineOff(i);
    
    Cl_temp_EngineOff = interp.Cl_scattered_EngineOff(M_temp,AoA_temp); % Determine coefficients without flap deflections. 
    Cd_temp_EngineOff = interp.Cd_scattered_EngineOff(M_temp,AoA_temp);
    Cm_temp_EngineOff = interp.Cm_scattered_EngineOff(M_temp,AoA_temp);
    
    Cl_temp_ViscousEngineOff = interp.Cl_scattered_Viscousaero_EngineOff(M_temp,AoA_temp,alt_temp/1000);
    Cd_temp_ViscousEngineOff = interp.Cd_scattered_Viscousaero_EngineOff(M_temp,AoA_temp,alt_temp/1000);
    
    
    %determine Flap Component
    Cd_temp_AoA0 = interp.Cd_scattered_EngineOff(M_temp,0); % Determine coefficients with no flap deflection as reference.
    Cl_temp_AoA0 = interp.Cl_scattered_EngineOff(M_temp,0);
    Cm_temp_AoA0 = interp.Cm_scattered_EngineOff(M_temp,0);
    
    Cl_AoA0_withflaps_temp_EngineOff = interp.flap_momentCl_scattered(M_temp,-(Cm_temp_EngineOff-Cm_temp_AoA0));  % Interpolate for coefficients with flap deflections. Removing portion of SPARTAN moment with no flap deflection.
    Cd_AoA0_withflaps_temp_EngineOff = interp.flap_momentCd_scattered(M_temp,-(Cm_temp_EngineOff-Cm_temp_AoA0));
    
    
    flap_Cl_temp_EngineOff = Cl_AoA0_withflaps_temp_EngineOff - Cl_temp_AoA0; % Remove portion of coefficient caused by SPARTAN. 
    flap_Cd_temp_EngineOff = Cd_AoA0_withflaps_temp_EngineOff - Cd_temp_AoA0;
    %
    
  % Create Grids
    I = cell(1, ndims(Mgrid_EngineOff)); 
    [I{:}] = ind2sub(size(Mgrid_EngineOff),i);
    
    Cl_Grid_EngineOff(I{(1)},I{(2)},I{(3)}) = Cl_temp_EngineOff+flap_Cl_temp_EngineOff+Cl_temp_ViscousEngineOff; % Add flap deflection coefficients in. This assumes that flap deflection will have equal effect over the range of Mach no.s.
    Cd_Grid_EngineOff(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOff+flap_Cd_temp_EngineOff+Cd_temp_ViscousEngineOff;
    Cm_Grid_EngineOff(I{(1)},I{(2)},I{(3)}) = Cm_temp_EngineOff;

    flap_Grid_EngineOff(I{(1)},I{(2)},I{(3)}) = interp.flap_momentdef_scattered(M_temp,-(Cm_temp_EngineOff-Cm_temp_AoA0)) ;
    
    Cl_Grid_ViscousEngineOff(I{(1)},I{(2)},I{(3)}) = Cl_temp_ViscousEngineOff;
    
    Cd_Grid_ViscousEngineOff(I{(1)},I{(2)},I{(3)}) = Cd_temp_ViscousEngineOff;
    
    Cl_Grid_EngineOffNoFlap(I{(1)},I{(2)},I{(3)}) = Cl_temp_EngineOff+Cl_temp_ViscousEngineOff;
    Cd_Grid_EngineOffNoFlap(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOff+Cd_temp_ViscousEngineOff;
    
%     Cl_Grid_test_EngineOff(I{(1)},I{(2)},I{(3)}) = Cl_temp_EngineOff; % Baseline test case without flap deflection. 
%     Cd_Grid_test_EngineOff(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOff;
%     Cm_Grid_test_EngineOff(I{(1)},I{(2)},I{(3)}) = Cm_temp_EngineOff;
%disp('viscous not being used')
    
%     Cl_Grid_EngineOff(I{(1)},I{(2)}) = Cl_temp;
%     Cd_Grid_EngineOff(I{(1)},I{(2)}) = Cd_temp;
%     Cm_Grid_EngineOff(I{(1)},I{(2)}) = Cm_temp;
end
Cl_spline_EngineOff = griddedInterpolant(Mgrid_EngineOff,AOAgrid_EngineOff,altgrid_EngineOff,Cl_Grid_EngineOff,'spline','linear');
Cd_spline_EngineOff = griddedInterpolant(Mgrid_EngineOff,AOAgrid_EngineOff,altgrid_EngineOff,Cd_Grid_EngineOff,'spline','linear');
flap_spline_EngineOff = griddedInterpolant(Mgrid_EngineOff,AOAgrid_EngineOff,altgrid_EngineOff,flap_Grid_EngineOff,'spline','linear');
Cm_spline_EngineOff = griddedInterpolant(Mgrid_EngineOff,AOAgrid_EngineOff,altgrid_EngineOff,Cm_Grid_EngineOff,'spline','linear');

Cd_spline_ViscousEngineOff = griddedInterpolant(Mgrid_EngineOff,AOAgrid_EngineOff,altgrid_EngineOff,Cd_Grid_ViscousEngineOff,'spline','linear');

%% Aerodynamic Data - Engine on 


interp.Cl_scattered_EngineOn = scatteredInterpolant(aero_EngineOn(:,1),aero_EngineOn(:,2),aero_EngineOn(:,3));
interp.Cd_scattered_EngineOn = scatteredInterpolant(aero_EngineOn(:,1),aero_EngineOn(:,2),aero_EngineOn(:,4));
interp.Cm_scattered_EngineOn = scatteredInterpolant(aero_EngineOn(:,1),aero_EngineOn(:,2),aero_EngineOn(:,5));

interp.Cl_scattered_Engine = scatteredInterpolant(aero_Engine(:,1),aero_Engine(:,2),aero_Engine(:,3),aero_Engine(:,4));
interp.Cd_scattered_Engine = scatteredInterpolant(aero_Engine(:,1),aero_Engine(:,2),aero_Engine(:,3),aero_Engine(:,5));
interp.Cm_scattered_Engine = scatteredInterpolant(aero_Engine(:,1),aero_Engine(:,2),aero_Engine(:,3),aero_Engine(:,6));

interp.Cl_scattered_Viscousaero_EngineOn = scatteredInterpolant(Viscousaero_EngineOn(:,1),Viscousaero_EngineOn(:,2),Viscousaero_EngineOn(:,3)/1000,Viscousaero_EngineOn(:,4));
interp.Cd_scattered_Viscousaero_EngineOn = scatteredInterpolant(Viscousaero_EngineOn(:,1),Viscousaero_EngineOn(:,2),Viscousaero_EngineOn(:,3)/1000,Viscousaero_EngineOn(:,5));

MList_EngineOn = unique(aero_EngineOn(:,1));
% MList_EngineOn(end+1) = MList_EngineOn(end) + 1; % extrapolate for Mach no slightly

AoAList_engineOn = unique(aero_EngineOn(:,2));

altList_engineOn = unique(aero_Engine(:,3)); % Use engine only case for this

[Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn] = ndgrid(MList_EngineOn,AoAList_engineOn,altList_engineOn);


% [Mgrid_EngineOn,AOAgrid_EngineOn] = ndgrid(MList_EngineOn,AoAList_engineOn);

Cl_Grid_EngineOn = [];
Cd_Grid_EngineOn = [];
Cm_Grid_EngineOn = [];
flap_Grid = [];

for i = 1:numel(Mgrid_EngineOn)
    M_temp = Mgrid_EngineOn(i);
    AoA_temp = AOAgrid_EngineOn(i);
    alt_temp = altgrid_EngineOn(i);
    
    
    %% PUT THIS BACK IN WHEN ADDING ENGINE, just taken out because of lack of alt right now 29/6
    % Also modify flaps below, and change interp in cehicle model
    
    %Calculate Thrust
%     
    L_ref = 2294.0;
    
    c = ppval(auxdata.interp.c_spline,alt_temp*1000); % Calculate speed of sound using atmospheric data

    v = M_temp*c;

    rho = ppval(auxdata.interp.rho_spline,alt_temp*1000); % Calculate density using atmospheric data

    q = 0.5 * rho .* (v .^2); % Calculating Dynamic Pressure

    T0 = ppval(auxdata.interp.T0_spline, alt_temp*1000); 

    P0 = ppval(auxdata.interp.P0_spline, alt_temp*1000);

    [Isp,Fueldt,eq,q1] = RESTint(M_temp, AoA_temp, auxdata,T0,P0);

    T = Isp.*Fueldt*9.81; % Thrust in direction of motion

    Tm = T*(CG_z-T_L)/(q*L_ref); %Thrust moment coefficient in same reference at the moments generated by CART3D


    %%
    
    
    Cl_temp_Engine = interp.Cl_scattered_Engine(M_temp,AoA_temp,alt_temp);
    Cd_temp_Engine = interp.Cd_scattered_Engine(M_temp,AoA_temp,alt_temp);
    Cm_temp_Engine = interp.Cm_scattered_Engine(M_temp,AoA_temp,alt_temp);

    Cl_temp_EngineOn = interp.Cl_scattered_EngineOn(M_temp,AoA_temp);
    Cd_temp_EngineOn = interp.Cd_scattered_EngineOn(M_temp,AoA_temp);
    Cm_temp_EngineOn = interp.Cm_scattered_EngineOn(M_temp,AoA_temp);
    
    Cl_temp_ViscousEngineOn = interp.Cl_scattered_Viscousaero_EngineOn(M_temp,AoA_temp,alt_temp);
    Cd_temp_ViscousEngineOn = interp.Cd_scattered_Viscousaero_EngineOn(M_temp,AoA_temp,alt_temp);
    
    %determine Flap Component
    Cd_temp_AoA0 = interp.Cd_scattered_EngineOff(M_temp,0); % engine off case used as reference for flaps (which also have engine off)
    Cl_temp_AoA0 = interp.Cl_scattered_EngineOff(M_temp,0);
    Cm_temp_AoA0 = interp.Cm_scattered_EngineOff(M_temp,0);
    
    Cl_AoA0_withflaps_temp_EngineOn = interp.flap_momentCl_scattered(M_temp,-(Cm_temp_EngineOn+Cm_temp_Engine+Tm-Cm_temp_AoA0));
    Cd_AoA0_withflaps_temp_EngineOn = interp.flap_momentCd_scattered(M_temp,-(Cm_temp_EngineOn+Cm_temp_Engine+Tm-Cm_temp_AoA0)) ;

%     Cl_AoA0_withflaps_temp_EngineOn = interp.flap_momentCl_scattered(M_temp,-(Cm_temp_EngineOn-Cm_temp_AoA0));
%     Cd_AoA0_withflaps_temp_EngineOn = interp.flap_momentCd_scattered(M_temp,-(Cm_temp_EngineOn-Cm_temp_AoA0)) ;
%     disp('Engine and viscous not being used')
    
    
    flap_Cl_temp_EngineOn = Cl_AoA0_withflaps_temp_EngineOn - Cl_temp_AoA0;
    flap_Cd_temp_EngineOn = Cd_AoA0_withflaps_temp_EngineOn - Cd_temp_AoA0;
    %
    
    % Create Grids
    I = cell(1, ndims(Mgrid_EngineOn)); 
    [I{:}] = ind2sub(size(Mgrid_EngineOn),i);
    
    Cl_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cl_temp_EngineOn+Cl_temp_Engine+Cl_temp_ViscousEngineOn+flap_Cl_temp_EngineOn;
    Cd_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOn+Cd_temp_Engine+Cd_temp_ViscousEngineOn+flap_Cd_temp_EngineOn; % forces include SPARTAN body, additional thrust from extra engine expantion and boat tail, viscous effects, and flaps
    Cm_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cm_temp_EngineOn;

    Cl_Grid_NoEngineNoFlap(I{(1)},I{(2)},I{(3)}) = Cl_temp_EngineOn+Cl_temp_ViscousEngineOn;
    Cl_Grid_ViscousEngineOn(I{(1)},I{(2)},I{(3)}) = Cl_temp_ViscousEngineOn;
    
    T_Grid(I{(1)},I{(2)},I{(3)}) = Cd_temp_Engine*q*auxdata.A+T; % Cd engine is 'drag' of extra engine expansion and boat tail (thrust)
    Isp_Grid(I{(1)},I{(2)},I{(3)}) = (Cd_temp_Engine*q*auxdata.A+T)/Fueldt/9.81;
    
    Cl_Grid_Engine(I{(1)},I{(2)},I{(3)}) = Cl_temp_Engine;
    Cd_Grid_Engine(I{(1)},I{(2)},I{(3)}) = Cd_temp_Engine;
    
    
    Cd_Grid_NoEngine(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOn+Cd_temp_ViscousEngineOn+flap_Cd_temp_EngineOn;
    Cd_Grid_ViscousEngineOn(I{(1)},I{(2)},I{(3)}) = Cd_temp_ViscousEngineOn;
    Cd_Grid_NoEngineNoFlap(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOn+Cd_temp_ViscousEngineOn;
% disp('Engine and viscous not being used')
%    Cl_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cl_temp_EngineOn+flap_Cl_temp_EngineOn;
%     Cd_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOn+flap_Cd_temp_EngineOn;
%     Cm_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cm_temp_EngineOn;
%     Cl_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cl_temp_Engine;
%     Cd_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cd_temp_Engine;
%     Cm_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cm_temp_EngineOn;
%     Cl_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cl_temp_ViscousEngineOn;
%     Cd_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cd_temp_ViscousEngineOn;
%     Cm_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = Cm_temp_EngineOn;

    flap_Grid_EngineOn(I{(1)},I{(2)},I{(3)}) = interp.flap_momentdef_scattered(M_temp,-(Cm_temp_EngineOn+Tm-Cm_temp_AoA0)) ;
% flap_Grid_EngineOn(I{(1)},I{(2)}) = interp.flap_momentdef_scattered(M_temp,-(Cm_temp_EngineOn-Cm_temp_AoA0)) ;    


%     Cl_Grid_test_EngineOn(I{(1)},I{(2)},I{(3)}) = Cl_temp_EngineOn;
%     Cd_Grid_test_EngineOn(I{(1)},I{(2)},I{(3)}) = Cd_temp_EngineOn;
%     Cm_Grid_test_EngineOn(I{(1)},I{(2)},I{(3)}) = Cm_temp_EngineOn;
%     
%     Cl_Grid_EngineOn(I{(1)},I{(2)}) = Cl_temp;
%     Cd_Grid_EngineOn(I{(1)},I{(2)}) = Cd_temp;
%     Cm_Grid_EngineOn(I{(1)},I{(2)}) = Cm_temp;
end
Cl_spline_EngineOn = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,Cl_Grid_EngineOn,'spline','linear');
Cd_spline_EngineOn = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,Cd_Grid_EngineOn,'spline','linear');
flap_spline_EngineOn = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,flap_Grid_EngineOn,'spline','linear');
Cm_spline_EngineOn = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,Cm_Grid_EngineOn,'spline','linear');

L_spline_Rear = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,Cl_Grid_Engine,'spline','linear');

T_spline_Rear = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,Cd_Grid_Engine,'spline','linear');

T_spline = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,T_Grid,'spline','linear');

Fd_spline_NoEngine = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,Cd_Grid_NoEngine,'spline','linear');
Cd_spline_ViscousEngineOn = griddedInterpolant(Mgrid_EngineOn,AOAgrid_EngineOn,altgrid_EngineOn,Cd_Grid_ViscousEngineOn,'spline','linear');


%%
plotaero = 'no'; % choose whether to plot a set of time-intensive contour plots to investigate the performance of the second stage vehicle
if strcmp(plotaero,'yes')

figure(4010)
contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),flap_Grid_EngineOn(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Flap Deflection, Engine On')
colormap jet
caxis([-20 20])
c = colorbar;
c.Label.String = 'Flap Deflection (deg)';

figure(4020)
contourf(Mgrid_EngineOff(:,:,3),AOAgrid_EngineOff(:,:,3),flap_Grid_EngineOff(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Flap Deflection, Engine Off')
colormap jet
caxis([-20 20])
c = colorbar;
c.Label.String = 'Flap Deflection (deg)';

figure(401)
contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),Cl_Grid_NoEngineNoFlap(:,:,3)./Cd_Grid_NoEngineNoFlap(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('L/D, Engine On')
c = colorbar;
c.Label.String = 'L/D';
figure(402)
contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),Cd_Grid_NoEngineNoFlap(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Drag Coefficient, Engine On')
c = colorbar;
c.Label.String = 'Drag Coefficient';
figure(403)
contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),Cl_Grid_NoEngineNoFlap(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Lift Coefficient, Engine On')
c = colorbar;
c.Label.String = 'Lift Coefficient';


figure(501)
contourf(Mgrid_EngineOff(:,:,3),AOAgrid_EngineOff(:,:,3),Cl_Grid_EngineOff(:,:,3)./Cd_Grid_EngineOff(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('L/D, Engine Off')
c = colorbar;
c.Label.String = 'L/D';
figure(502)
contourf(Mgrid_EngineOff(:,:,3),AOAgrid_EngineOff(:,:,3),Cd_Grid_EngineOff(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Drag Coefficient, Engine Off')
c = colorbar;
c.Label.String = 'Drag Coefficient';
figure(503)
contourf(Mgrid_EngineOff(:,:,3),AOAgrid_EngineOff(:,:,3),Cl_Grid_EngineOff(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Lift Coefficient, Engine Off')
c = colorbar;
c.Label.String = 'Lift Coefficient';


figure(504)
contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),Cl_Grid_EngineOn(:,:,3)./Cd_Grid_EngineOn(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('L/D, Engine On')
c = colorbar;
c.Label.String = 'L/D';
figure(505)
contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),Cd_Grid_EngineOn(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Drag Coefficient, Engine On')
c = colorbar;
c.Label.String = 'Drag Coefficient';
figure(506)
contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),Cl_Grid_EngineOn(:,:,3),3000,'LineColor','none')
xlabel('Mach no.')
ylabel('Angle of Attack (deg)')
title('Lift Coefficient, Engine On')
c = colorbar;
c.Label.String = 'Lift Coefficient';
% 
% figure(404)
% contourf(permute(AOAgrid_EngineOn(3,:,:),[3 2 1]),permute(altgrid_EngineOn(3,:,:),[3 2 1]),permute(Cl_Grid_EngineOn(3,:,:),[3 2 1]),3000,'LineColor','none')
% xlabel('Mach no.')
% ylabel('Angle of Attack (deg)')
% title('Lift Coefficient, Engine On')
% c = colorbar;
% c.Label.String = 'Lift Coefficient';
% 
% 
% figure(405)
% contourf(permute(AOAgrid_EngineOn(1,:,:),[3 2 1]),permute(altgrid_EngineOn(1,:,:),[3 2 1]),permute(Cd_Grid_ViscousEngineOn(1,:,:),[3 2 1]),3000,'LineColor','none')
% xlabel('Angle of Attack (deg)')
% ylabel('Altitude (km)')
% title('Viscous Drag Coefficient, Engine On, Mach 5')
% c = colorbar;
% c.Label.String = 'Drag Coefficient';
% 
% figure(406)
% contourf(permute(AOAgrid_EngineOn(3,:,:),[3 2 1]),permute(altgrid_EngineOn(3,:,:),[3 2 1]),permute(Cd_Grid_ViscousEngineOn(3,:,:),[3 2 1]),3000,'LineColor','none')
% xlabel('Angle of Attack (deg)')
% ylabel('Altitude (km)')
% title('Viscous Drag Coefficient, Engine On, Mach 7')
% colormap jet
% caxis([0 0.02])
% c = colorbar;
% c.Label.String = 'Drag Coefficient';
% 
% figure(506)
% contourf(permute(AOAgrid_EngineOff(8,:,:),[3 2 1]),permute(altgrid_EngineOff(8,:,:),[3 2 1])/1000,permute(Cd_Grid_ViscousEngineOff(8,:,:),[3 2 1]),3000,'LineColor','none')
% xlabel('Angle of Attack (deg)')
% ylabel('Altitude (km)')
% title('Viscous Drag Coefficient, Engine Off, Mach 7')
% colormap jet
% caxis([0 0.02])
% c = colorbar;
% c.Label.String = 'Drag Coefficient';
% 
% figure(507)
% contourf(permute(AOAgrid_EngineOff(5,:,:),[3 2 1]),permute(altgrid_EngineOff(5,:,:),[3 2 1])/1000,permute(Cd_Grid_ViscousEngineOff(5,:,:),[3 2 1]),3000,'LineColor','none')
% xlabel('Angle of Attack (deg)')
% ylabel('Altitude (km)')
% title('Viscous Drag Coefficient, Engine Off, Mach 3')
% colormap jet
% caxis([0 0.02])
% c = colorbar;
% c.Label.String = 'Drag Coefficient';
% 
% figure(508)
% contourf(permute(AOAgrid_EngineOff(3,:,:),[3 2 1]),permute(altgrid_EngineOff(3,:,:),[3 2 1])/1000,permute(Cd_Grid_ViscousEngineOff(3,:,:),[3 2 1]),3000,'LineColor','none')
% xlabel('Angle of Attack (deg)')
% ylabel('Altitude (km)')
% title('Viscous Drag Coefficient, Engine Off, Mach 0.9')
% colormap jet
% caxis([0 0.02])
% c = colorbar;
% c.Label.String = 'Drag Coefficient';
% 
% figure(407)
% contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),T_Grid(:,:,3)/1000,3000,'LineColor','none')
% xlabel('Mach no.')
% ylabel('Angle of Attack (deg)')
% title('Thrust')
% c = colorbar;
% c.Label.String = 'Thrust (kN)';
% figure(408)
% contourf(Mgrid_EngineOn(:,:,3),AOAgrid_EngineOn(:,:,3),Isp_Grid(:,:,3),3000,'LineColor','none')
% xlabel('Mach no.')
% ylabel('Angle of Attack (deg)')
% title('Isp')
% c = colorbar;
% c.Label.String = 'Specific Impulse (s)';
end
