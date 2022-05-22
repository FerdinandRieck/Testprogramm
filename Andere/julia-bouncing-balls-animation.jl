#!/usr/bin/env julia

using Luxor, Colors, Combinatorics

type Ball
    id::Int
    position::Point
    velocity::Point
    color::Color
    ballradius::Float64
end

function backdropf(scene, framenumber)
    background("white")
end

function collisioncheck(balls)
    for ballpair in combinations(1:length(balls), 2)
        balla, ballb = balls[ballpair[1]], balls[ballpair[2]]
        if intersection2circles(balla.position, balla.ballradius, ballb.position, ballb.ballradius) > 0.01
            collision = ballb.position - balla.position
            distance = norm(ballb.position, balla.position)
            # Get the components of the velocity vectors which are parallel to the collision.
            # The perpendicular component remains the same for both
            collision = (collision / distance)
            aci = dot(balla.velocity, collision)
            bci = dot(ballb.velocity, collision)

            # new velocities using the 1-dimensional elastic collision equations
            # masses are the same
            acf = bci
            bcf = aci
            # replace the velocity components
            balls[ballpair[1]].velocity += (acf - aci) * collision
            balls[ballpair[2]].velocity += (bcf - bci) * collision
        end
    end
    return balls
end

function update(scene, framenumber, balls)
    setopacity(0.9)
    panes = Tiler(scene.movie.width, scene.movie.height, 1, 2, margin=0)
    panecenters = first.(collect(panes))
    panewidth = panes.tilewidth/2
    paneheight = panes.tileheight/2
    balls = collisioncheck(balls)
    # on the left 
    @layer begin
        translate(panecenters[1])
        sethue("black")
        box(O, 2panewidth, 2paneheight, :stroke)
        for ball in balls
            ball.position = ball.position += ball.velocity
            if (ball.position.x <= (-panewidth + ball.ballradius))
                ball.position = Point(-panewidth + ball.ballradius, ball.position.y)
                ball.velocity = Point(-ball.velocity.x, ball.velocity.y)
            end
            if (ball.position.x >= (panewidth - ball.ballradius))
                ball.position = Point(panewidth - ball.ballradius, ball.position.y)
                ball.velocity = Point(-ball.velocity.x, ball.velocity.y)
            end
            if (ball.position.y <= (-paneheight + ball.ballradius))
                ball.position = Point(ball.position.x, -panewidth + ball.ballradius)
                ball.velocity = Point(ball.velocity.x, -ball.velocity.y)
            end
            if (ball.position.y >= (paneheight - ball.ballradius))
                ball.position = Point(ball.position.x, panewidth - ball.ballradius)
                ball.velocity = Point(ball.velocity.x, -ball.velocity.y)
            end
            sethue(ball.color)
            circle(ball.position, ball.ballradius, :fill)
        end
    end
    # do the right thing
    @layer begin
        sethue("black")
        fontsize(14)
        fontface("Menlo")
        translate(panecenters[2])
        data = [(b.position.x, b.position.y) for b in balls]
        stringdata = map(x -> string(convert.(Int, floor.(x))), data)
        textbox(stringdata, O - (panewidth, paneheight) + (5, 5), leading=20)
    end
end

function main()
    juliaballmovie = Movie(256, 128, "juliaballs")
    initialpts = ngon(O + (0, 10), 35, 3, pi/6, vertices=true)
    ballradius = 14    
    balls = [
    # set position and initial velocity vectors
    Ball(1, initialpts[1], initialpts[3]/30, colorant"brown3", ballradius),
    Ball(2, initialpts[2], initialpts[2]/30, colorant"forestgreen", ballradius),
    Ball(3, initialpts[3], initialpts[1]/40, colorant"mediumorchid3", ballradius)
    ]
    animate(juliaballmovie, [
        Scene(juliaballmovie, backdropf, 1:1200),
        Scene(juliaballmovie, (s, f) -> update(s, f, balls), 1:1200),
        ], framerate=30,  creategif=true, pathname="/tmp/juliapool.gif" )
end

main()
