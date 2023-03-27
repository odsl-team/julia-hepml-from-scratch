# This file is licensed under the MIT License (MIT).

using Random, Optimisers
import LogExpFunctions
import Flux, Zygote, Optimisers, MLUtils
import ProgressMeter


rng = Random.default_rng()

# Construct the layer
model = Flux.Chain(
    Flux.Dense(18, 128, Flux.relu),
    Flux.Dense(128, 128, Flux.relu),
    Flux.Dense(128, 1, Flux.sigmoid)
) |> Flux.gpu



Flux.binarycrossentropy(model(X_train[:, 1:10000]), L_train[:,1:10000])

optim = Flux.setup(Flux.Adam(), model)

n_epochs = 4
batchsize = 5000

dataloader = MLUtils.DataLoader((X_train, L_train), batchsize=batchsize, shuffle=true, rng = Random.MersenneTwister(2718))

loss_history = zeros(0)
p = ProgressMeter.Progress(n_epochs * length(dataloader), 0.1, "Training...")
for epoch in 1:n_epochs
    for (x, y) in dataloader
        loss_train, grads = Flux.withgradient(model) do m
            # Evaluate model and loss inside gradient context:
            y_hat = m(x)
            Flux.binarycrossentropy(y_hat, y)
        end
        push!(loss_history, loss_train)
        ProgressMeter.next!(p; showvalues = [(:loss_train, loss_train),#= (:loss_test, loss_test)=#])
        Flux.update!(optim, model, grads[1])
    end
end
ProgressMeter.finish!(p)

plot(loss_history)
