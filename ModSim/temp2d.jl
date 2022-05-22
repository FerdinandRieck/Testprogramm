# example: temperature 2D
# compute, show, produce video
# author of original version: Gerd Steinebach
# modifications and extensions by Tanja Clees

using DifferentialEquations, Plots 
using VectorizedRoutines # für Matlab.meshgrid
using SparseArrays # für sparse function in jacstru

#---------------------------------------
# functions
function dgl!(dy1,y,p,t) 
    N, dx, tau, ix1, ix2, iy, rho, dicke = p
    dy = zeros(N,N); T = reshape(y,N,N); 
    for i = 1:N
        for j=1:N 
            dy[i,j] = 0.0; 
            if (i==1)
                dy[i,j] = dy[i,j] + T[i+1,j]-T[i,j];
            elseif (i==N)
                dy[i,j] = dy[i,j] - T[i,j]+T[i-1,j];
            else
                dy[i,j]= dy[i,j]+T[i+1,j]-2*T[i,j]+T[i-1,j];
            end
            if (j==1)
                dy[i,j] = dy[i,j] + T[i,j+1]-T[i,j];
            elseif (j==N)
                dy[i,j] = dy[i,j] - T[i,j]+T[i,j-1];
            else
                dy[i,j]= dy[i,j]+T[i,j+1]-2*T[i,j]+T[i,j-1];
            end
            dy[i,j] = dy[i,j]*tau/dx^2;
        end
    end
    if t < 20
        dy[iy,ix1] = dy[iy,ix1] + P/(c*rho*dx^2*dicke); 
        dy[iy,ix2] = dy[iy,ix2] + P/(c*rho*dx^2*dicke);  # nur eine 
    end
    dy = dy.- 50 * dx^2*(T.-T0)/(c*rho*dx^2*dicke);
    #dy = dy.- 50 * (T.-T0)/(c*rho*dicke)
    dy1[:] = reshape(dy,N*N,1)
    nothing
end

function jacstru(N,J,u,p,t)
    J = Matrix{Float64}(I,N*N,N*N)
    for k=1:N*N
        if (k>1) J[k,k-1]=1; end
        if (k>N) J[k,k-N]=1; end
        if (k<N*N) J[k,k+1]=1; end
        if (k<=N*N-N) J[k,k+N]=1; end
    end
    J = sparse(J);
    println(1)
    nothing
end
#---------------------------------------
    
#--function temp_2d
lam=237; c=900; rho=2700; tau=lam/(c*rho);
T0=20; P=5; L=0.07; dicke=0.0025; N=40; dx=L/(N-1);
ix1  = 12; ix2  = 29; iy  =  20
#ix1  = 2; ix2  = 2; iy  =  2
param = N, dx, tau, ix1, ix2, iy, rho, dicke
XY = Matlab.meshgrid(0:dx:L);
X = XY[1]; Y = XY[2]
T = zeros(N,N).+T0; y0 = reshape(T,:,1)
tend = 40.0; tspan = [0.0,tend]
#f = ODEFunction(dgl!;jac=jacstru)
f = ODEFunction(dgl!)                 # ohne jacstru
prob = ODEProblem(f,y0,tspan,param)
@time sol = solve(prob,Tsit5()) 
#@time sol = solve(prob,Rodas4P2(autodiff=false)) 

# Plot 
tt = 0.0:0.1:tend;
nt = length(tt)
anim = @animate for i = 1:nt-1
    T = sol(tt[i])
    T = reshape(T,N,N)
    plot(X,Y,T,st=:surface,zlims=(18, 32))
end
gif(anim, "temperature_2D.gif", fps = 100)

