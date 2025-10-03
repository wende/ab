ExUnit.start()

# Configure ExUnit for property-based testing
# seed: 0 ensures tests always run in the same order
ExUnit.configure(exclude: [skip: true], trace: true, seed: 0)
