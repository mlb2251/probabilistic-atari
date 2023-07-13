using Revise
using Gen
using GenParticleFilters

function get_mask_diff(mask1, mask2, color1, color2)
    #doesn't use color yet
    # isapprox(color1, color2) && return 1
    !isapprox(color1, color2) && return 1.
    size(mask1) != size(mask2) && return 1.
    # average difference in mask
    sum(i -> abs(mask1[i] - mask2[i]), eachindex(mask1)) / length(mask1)
    #look into the similarity of max overlap thing 
end 
    

"""
groups adjacent same-color pixels of a frame into objects
as a simple first pass of object detection
"""


# @gen function randomness(height, width)
#     hi ~ uniform_discrete(1, height)	#don;t actually want hi in the trace, look at split nerge example. one func for randomness
#     wi ~ uniform_discrete(1, width)
# end


# @gen function randomness(tr)
#     #hilist is empty list of integers 
#     hilist = []
#     #wilist is empty list of integers
#     wilist = []



#     #aaa idk if this datastructure works mappp aa 
#     for i=1:tr[:init => :num_sprite_types]
#         shape = tr[:init => :init_sprites => i => :shape]
#         height, width = size(shape)
#         hi ~ uniform_discrete(1, height)	#don;t actually want hi in the trace, look at split nerge example. one func for randomness
#         wi ~ uniform_discrete(1, width)
#         push!(hilist, hi)
#         push!(wilist, wi)
#     end
#     #return hilist, wilist
#     {hilist} = hilist
#     {wilist} = wilist
# end 

# @gen function rand_hi_wi(i, tr)
#     shape = tr[:init => :init_sprites => i => :shape]
#     height, width = size(shape)
#     hi ~ uniform_discrete(1, height)	#don;t actually want hi in the trace, look at split nerge example. one func for randomness
#     wi ~ uniform_discrete(1, width)

#     return (hi, wi)
# end 

@gen function get_random(tr)
    #shape things 
    shapei ~ uniform_discrete(1, tr[:init => :num_sprite_types])	
    shape = tr[:init => :init_sprites => shapei => :shape]
    height, width = size(shape)
    hi ~ uniform_discrete(1, height) 
    wi ~ uniform_discrete(1, width)	

    #color things 
    colori ~ uniform_discrete(1, tr[:init => :num_sprite_types])
    rcolorshift ~ normal(0.0, 0.1)
    gcolorshift ~ normal(0.0, 0.1)	
    bcolorshift ~ normal(0.0, 0.1)

end 

@gen function get_random_for_i(tr, i)
    #shape things 
    # shapei ~ uniform_discrete(1, tr[:init => :num_sprite_types])	
    # shape = tr[:init => :init_sprites => shapei => :shape]
    # height, width = size(shape)
    # hi ~ uniform_discrete(1, height) 
    # wi ~ uniform_discrete(1, width)	

    #color things 
    #colori ~ uniform_discrete(1, tr[:init => :num_sprite_types])
    rcolorshift ~ normal(0.0, 0.1)
    gcolorshift ~ normal(0.0, 0.1)	
    bcolorshift ~ normal(0.0, 0.1)

end 

# #should do mh for each sprite separately
# all_rand_hi_wi = Map(rand_hi_wi)


# @gen function rand_hilist_wilist(tr) #collect broke it?? what? is going on/ 
#     hilist ~ all_rand_hi_wi(1:tr[:init => :num_sprite_types], [tr for _ in 1:tr[:init => :num_sprite_types]])
#     @show hilist
#     wilist ~ all_rand_hi_wi(1:tr[:init => :num_sprite_types], [tr for _ in 1:tr[:init => :num_sprite_types]])
#     @show wilist
# end 
    



# @gen function rand_hi_wi(tr)
#     for i in range (1, tr[:init => :num_sprite_types])
#         shape = tr[:init => :init_sprites => i => :shape]
#         height, width = size(shape)
#         hi ~ uniform_discrete(1, height)	#don;t actually want hi in the trace, look at split nerge example. one func for randomness
#         wi ~ uniform_discrete(1, width)
#     end



# @gen function small_shape_change(tr, sprite_index)
#     shape = tr[:init => :init_sprites => sprite_index => :shape]
#     height, width = size(shape)
#     hi ~ uniform_discrete(1, height)	#don;t actually want hi in the trace, look at split nerge example. one func for randomness
#     wi ~ uniform_discrete(1, width)
    	

#     #change shape at hi, wi
#     shape[hi, wi] = 1 - shape[hi, wi]

#     {(:init => :init_sprites => sprite_index => :shape)} = shape #need to find a way for this to be a 
# end 

#involution 
function update_detect(tr, random_choices, retval, for_args)
    #@show random_choices
    new_trace_choices = choicemap()
    backward_choices = choicemap()

    #update num objects 
    tr, = mh(tr, select(:N))

    #update num sprites 
    tr, = mh(tr, select(:num_sprite_types))

    #update object positions
    for i=1:tr[:init => :N]#init defined in model
        tr, = mh(tr, select((:init => :init_objs => i => :pos))) #correct? 
    end

    #recolor sprites 
    # for i=1:tr[:init => :num_sprite_types]
    #     #@show tr[:init => :init_sprites => i => :color]
    #     tr, = mh(tr, select((:init => :init_sprites => i => :color))) 
    # end
    
    colori = random_choices[:colori]
    rcolornew = random_choices[:rcolorshift] + tr[:init => :init_sprites => colori => :color][1]
    gcolornew = random_choices[:gcolorshift] + tr[:init => :init_sprites => colori => :color][2]
    bcolornew = random_choices[:bcolorshift] + tr[:init => :init_sprites => colori => :color][3]

    new_trace_choices[(:init => :init_sprites => colori => :color)] = [rcolornew, gcolornew, bcolornew]	
    #backward_choices[(:init => :init_sprites => colori => :color)] = tr[:init => :init_sprites => colori => :color]
    backward_choices[:colori] = colori	
    backward_choices[:rcolorshift] = - random_choices[:rcolorshift]
    backward_choices[:gcolorshift] = - random_choices[:gcolorshift]
    backward_choices[:bcolorshift] = - random_choices[:bcolorshift]

    #resprite objects
    for i=1:tr[:init => :N]
        tr, = mh(tr, select((:init => :init_objs => i => :sprite_index))) 
    end

    #reshape objects TODO
    #@show get_args(random_choices)
    

    # # hilist = random_choices[:hilist] 	
    # # @show hilist
    # # wilist = random_choices[:wilist]	
    # for i=1:tr[:init => :num_sprite_types]
    #     @show random_choices[:hilist -> i -> :hi]


    #     hi = hilist[i]	
    #     wi = wilist[i]	
    #     shape = tr[:init => :init_sprites => i => :shape]
    #     #backward_choices[(:init => :init_sprites => i => :shape)] = shape
    #     backward_choices[:hilist] = hilist
    #     backward_choices[:wilist] = wilist
    #     shape[hi, wi] = 1 - shape[hi, wi] 
    #     #{(:init => :init_sprites => i => :shape)} = shape 
    #     new_trace_choices[(:init => :init_sprites => i => :shape)] = shape

    #     #tr = mh(tr, small_shape_change, (tr, i,))
    #     #tr, = mh(tr, select((:init => :init_sprites => i => :shape))) 
    # end


    #reshape objects new way 
    backward_choices[:shapei] = random_choices[:shapei]
    backward_choices[:hi] = random_choices[:hi]
    backward_choices[:wi] = random_choices[:wi]

    shapei = random_choices[:shapei]
    hi = random_choices[:hi]
    wi = random_choices[:wi]

    shape = tr[:init => :init_sprites => shapei => :shape]
    shape[hi, wi] = 1 - shape[hi, wi]
    new_trace_choices[(:init => :init_sprites => shapei => :shape)] = shape




    #add/delete TODO

    #split/merge TODO
    
    new_trace, weight, = update(tr, get_args(tr), (NoChange(),), new_trace_choices)
    (new_trace, backward_choices, weight)
end


function update_detect_for_i(tr, random_choices, retval, for_args)
    #how to get i from for_arfs
    i = for_args[1]

    new_trace_choices = choicemap()
    backward_choices = choicemap()
    
    rcolornew = random_choices[:rcolorshift] + tr[:init => :init_sprites => i => :color][1]
    gcolornew = random_choices[:gcolorshift] + tr[:init => :init_sprites => i => :color][2]
    bcolornew = random_choices[:bcolorshift] + tr[:init => :init_sprites => i => :color][3]

    new_trace_choices[(:init => :init_sprites => i => :color)] = [rcolornew, gcolornew, bcolornew]	

    backward_choices[:rcolorshift] = - random_choices[:rcolorshift]
    backward_choices[:gcolorshift] = - random_choices[:gcolorshift]
    backward_choices[:bcolorshift] = - random_choices[:bcolorshift]

end 



function process_first_frame_v2(frame, threshold=.05)
    #run update detect a bunch TODO 

    (C, H, W) = size(frame)

    #something like this but edit
    init_obs = choicemap(
        (:init => :observed_image, frame),
        
        #have perfect build init obs here for everything else and one by one delete 
        #(:init => :N, length(objs)),
        #(:init => :num_sprite_types, length(sprites)),
    )

    tr = generate(model, (H, W, 1), init_obs)[1]

    for num_updates in 1:100 #no clue 
        #tr = update_detect(tr, rand_hilist_wilist ,frame)
        tr, accepted = mh(tr, get_random, (), update_detect)#tr is an arg but it is assumed
        @show tr[:init => :init_sprites => 1 => :color]

        

        #sprite by sprite version
        for i in 1:tr[:init => :num_sprite_types]
            tr, accepted = mh(tr, get_random_for_i, (i,), update_detect_for_i)#tr is an arg but it is assumed
            
        end

    end





    #init_obs = choicemap 

    #@show tr 
    

    Gen.get_choices(tr)	

end 

function process_first_frame(frame, threshold=.05)
    (C, H, W) = size(frame)

    # contiguous color
    cluster = zeros(Int, H, W)
    curr_cluster = 0

    pixel_stack = Tuple{Int,Int}[]

    for x in 1:W, y in 1:H
        # @show x,y

        # skip if already assigned to a cluster
        cluster[y,x] != 0 && continue

        # create a new cluster
        curr_cluster += 1
        # println("cluster: $curr_cluster")

        @assert isempty(pixel_stack)
        push!(pixel_stack, (y,x))

        while !isempty(pixel_stack)
            (y,x) = pop!(pixel_stack)

            for (dy,dx) in ((0,-1), (-1,0), (0,1), (1,0), (1,1), (1,-1), (-1,1), (-1,-1))
                (x+dx > 0 && y+dy > 0 && x+dx <= W && y+dy <= H) || continue

                # skip if already assigned to a cluster
                cluster[y+dy,x+dx] != 0 && continue
                
                # if the average difference between channel values
                # is greater than a cutoff, then the colors are different
                # and we can't add this to the cluster

                # #fusing version
                #sum(abs.(frame[:,y+dy,x+dx] .- frame[:,y,x]))/3 < threshold || continue

                #nonfusing version 
                sum(i -> abs(frame[i, y+dy, x+dx] - frame[i, y, x]), eachindex(frame[:, y, x])) / 3 < threshold || continue 

                # isapprox(frame[:,y+dy,x+dx], frame[:,y,x]) || continue

                # add to cluster
                cluster[y+dy,x+dx] = curr_cluster
                push!(pixel_stack, (y+dy,x+dx))
            end
        end
    end



    # (start_y, start_x, end_y, end_x)
    smallest_y = [typemax(Int) for _ in 1:curr_cluster]
    smallest_x = [typemax(Int) for _ in 1:curr_cluster]
    largest_y = [typemin(Int) for _ in 1:curr_cluster]
    largest_x = [typemin(Int) for _ in 1:curr_cluster]
    color = [[0.,0.,0.] for _ in 1:curr_cluster]

    for x in 1:W, y in 1:H
        c = cluster[y,x]
        smallest_y[c] = min(smallest_y[c], y)
        smallest_x[c] = min(smallest_x[c], x)
        largest_y[c] = max(largest_y[c], y)
        largest_x[c] = max(largest_x[c], x)
        color[c] += frame[:,y,x]
    end

    objs = Object[]
    sprites = Sprite[]

    background = 0
    background_size = 0
    for c in 1:curr_cluster
        # create the sprite mask and crop it so its at 0,0
        mask = (cluster .== c)[smallest_y[c]:largest_y[c], smallest_x[c]:largest_x[c]]
        # avg color
        #uncomment. correct code 
        color[c] ./= sum(mask)
        #@show color[c]
        #make array of 3 random numbers to assign to color

        ##random colors for testing 
        #color[c] = rand(Float64, (3)) 

        # largest area sprite is background
        if sum(mask) > background_size
            background = c
            background_size = sum(mask)
        end

        #v2 same sprite type if similar masks 
        newsprite = true
        mask_diff = 0.
        for (i,sprite) in enumerate(sprites)

            #difference in sprite masks
            mask_diff = get_mask_diff(sprite.mask, mask, sprite.color, color[c])
            # @show mask_diff

            #same sprite
            if mask_diff < 0.1
                newsprite = false
                object = Object(i, Position(smallest_y[c], smallest_x[c]))
                push!(objs, object)
                break
            end

            iH,iW = size(sprite.mask)
            cH,cW = size(mask)


        end	


        #new sprite 
        if newsprite
            println("newsprite $(length(sprites)) from cluster $c")
            sprite_type = Sprite(mask, color[c])
            push!(sprites, sprite_type)
            object = Object(length(sprites), Position(smallest_y[c], smallest_x[c]))
            push!(objs, object)
        end

    end

    # turn background into a big rectangle filling whole screen

    #i think works even with spriteindex 
    color = sprites[background].color
    sprites[background] = Sprite(ones(Bool, H, W),color)
    objs[background] = Object(background, Position(1,1))

    (cluster,objs,sprites)	

end

function build_init_obs(H,W, sprites, objs, observed_images)
    init_obs = choicemap(
        (:init => :observed_image, observed_images[:,:,:,1]),
        (:init => :N, length(objs)),
        (:init => :num_sprite_types, length(sprites)),
    )

    for (i,obj) in enumerate(objs)
        # @show obj.sprite_index
        @assert 0 < obj.pos.x <= W && 0 < obj.pos.y <= H
        init_obs[(:init => :init_objs => i => :pos)] = obj.pos
        init_obs[(:init => :init_objs => i => :sprite_index)] = obj.sprite_index #anything not set here it makes a random choice about

        #EDIT THIS 
        init_obs[:init => :init_sprites => obj.sprite_index => :shape] = sprites[obj.sprite_index].mask # => means go into subtrace, here initializing subtraces, () are optional. => means pair!!
        init_obs[:init => :init_sprites => obj.sprite_index => :color] = sprites[obj.sprite_index].color
    end
    init_obs
end

"""
Runs a particle filter on a sequence of frames
"""
function particle_filter(num_particles::Int, observed_images::Array{Float64,4}, num_samples::Int)
    C,H,W,T = size(observed_images)

    # construct initial observations
    (cluster, objs, sprites) = process_first_frame(observed_images[:,:,:,1])

    #init_obs = build_init_obs(H,W, sprites, objs, observed_images)

    #new version 
    init_obs = process_first_frame_v2(observed_images[:,:,:,1])


    state = pf_initialize(model, (H,W,1), init_obs, num_particles)

    # steps
    elapsed=@elapsed for t in 1:T-1
        @show t
        # @show state.log_weights, weights
        # maybe_resample!(state, ess_threshold=num_particles/2, verbose=true)
        obs = choicemap((:steps => t => :observed_image, observed_images[:,:,:,t]))
        # particle_filter_step!(state, (H,W,t), (NoChange(),NoChange(),UnknownChange()), obs)
        @time pf_update!(state, (H,W,t+1), (NoChange(),NoChange(),UnknownChange()),
            obs, grid_proposal, (obs,))
    end

    (_, log_normalized_weights) = Gen.normalize_weights(state.log_weights)
    weights = exp.(log_normalized_weights)

    # print and render results

    secs_per_step = round(elapsed/(T-1),sigdigits=3)
    fps = round(1/secs_per_step,sigdigits=3)
    time_str = "particle filter runtime: $(round(elapsed,sigdigits=3))s; $(secs_per_step)s/frame; $fps fps ($num_particles particles))"
    println(time_str)

    html_body("<p>C: $C, H: $H, W: $W, T: $T</p>")
    html_body("<h2>Observations</h2>", html_gif(observed_images))
    types = map(i -> objs[i].sprite_index, cluster);
    html_body("<h2>First Frame Processing</h2>",
    html_table(["Observation"                       "Objects"                       "Types";
             html_img(observed_images[:,:,:,1])  html_img(color_labels(cluster)[1])  html_img(color_labels(types)[1])
    ]))
    html_body("<h2>Reconstructed Images</h2>")

    table = fill("", 2, length(state.traces))
    for (i,trace) in enumerate(state.traces)
        table[1,i] = "Particle $i ($(round(weights[i],sigdigits=4)))"
        table[2,i] = html_gif(render_trace(trace));
    end

    html_body(html_table(table))
    html_body(time_str)
    
    return sample_unweighted_traces(state, num_samples)
end

import FunctionalCollections

"""
Does gridding to propose new positions for an object in the vicinity
of the current position
"""
@gen function grid_proposal(prev_trace, obs)

    (H,W,prev_T) = get_args(prev_trace)

    t = prev_T
    grid_size = 2
    observed_image = obs[(:steps => t => :observed_image)]

    prev_objs = objs_from_trace(prev_trace, t - 1)
    prev_sprites = sprites_from_trace(prev_trace, 0)

    # now for each object, propose and sample changes 
    for obj_id in 1:prev_trace[:init => :N]

        # get previous position
        if t == 1
            prev_pos = prev_trace[:init => :init_objs => obj_id => :pos]
        else
            prev_pos = prev_trace[:steps => t - 1 => :objs => obj_id => :pos]
        end

        #way to get positions that avoids negatives, todo fix 
        positions = Position[]
        for dx in -grid_size:grid_size,
            dy in -grid_size:grid_size
            #hacky since it cant handle negatives rn
            if prev_pos.x + dx < 1 || prev_pos.x + dx > W || prev_pos.y + dy < 1 || prev_pos.y + dy > H
                push!(positions, Position(prev_pos.y, prev_pos.x))
            else
                push!(positions, Position(prev_pos.y+dy, prev_pos.x+dx))
            end
        end
        
        # flatten
        positions = reshape(positions, :)
        
        # # total update slower version 
        # traces = [Gen.update(trace,choicemap((:steps => t => :objs => obj_id => :pos) => pos))[1] for pos in positions]

        #manually update, partial draw
        scores = Float64[]
        #for each position, score the new image section around the object 
        for pos in positions
            #making the objects with just that object moved 
            objects_one_moved = prev_objs[:]
            objects_one_moved[obj_id] = Object(objects_one_moved[obj_id].sprite_index, pos)

            (sprite_height, sprite_width) = size(prev_sprites[prev_objs[obj_id].sprite_index].mask)
            
            (_, H, W) = size(observed_image)

            #making the little box to render 
            relevant_box_min_y = min(pos.y, prev_pos.y)
            relevant_box_max_y = min(max(pos.y + sprite_height, prev_pos.y + sprite_height), H)
            relevant_box_min_x = min(pos.x, prev_pos.x)
            relevant_box_max_x = min(max(pos.x + sprite_width, prev_pos.x + sprite_width), W)

            drawn_moved_obj = draw_region(objects_one_moved, prev_sprites, relevant_box_min_y, relevant_box_max_y, relevant_box_min_x, relevant_box_max_x) 
            #is it likely
            score = Gen.logpdf(image_likelihood, observed_image[:, relevant_box_min_y:relevant_box_max_y, relevant_box_min_x:relevant_box_max_x], drawn_moved_obj, 0.1)#can I hardcode that

            push!(scores, score)
        end 

        #update sprite index? todo?
        
        #making the scores into probabilities 
        scores_logsumexp = logsumexp(scores)
        scores =  exp.(scores .- scores_logsumexp)

        #oldver
        #scores = Gen.normalize_weights(get_score.(traces))[2]
        #scores = exp.(scores)

        # sample the actual position
        pos = {:steps => t => :objs => obj_id => :pos} ~ labeled_cat(positions, scores)

        # old version: set the curr `trace` to this trace for future iterations of this loop
        # idx = findfirst(x -> x == pos, positions)
        # objs[obj_id] = Object(objs[obj_id].sprite, positions[idx]) 
        # trace = traces[idx]
    end
    nothing 

    #for each sprite type, propose and sample changes
    #todo 
end


# end # module Inference


