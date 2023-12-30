//
//  Create.swift
//  System Modelling
//
//  Created by yasha on 03.11.2023.
//

struct CreatorDelay<T> {
    let delayMean: Double
    let probability: Double
    let distribution: Distribution
    let itemGenerator: () -> T?
    var delayDeviation: Double = 0.0
    let k: Int
    
    init(delayMean: Double, probability: Double, _ distribution: Distribution, k: Int = 1, _ itemGenerator: @escaping () -> T? = { return nil }) {
        self.delayMean = delayMean
        self.probability = probability
        self.distribution = distribution
        self.k = k
        self.itemGenerator = itemGenerator
    }
}

class Create<T>: Element<T> {
    
    private let delays: [CreatorDelay<T>]
    
    init(delays: [CreatorDelay<T>], name: String, chooseBy type: NextElementsChooseType = .priority) {
        self.delays = delays
        super.init(delay: 1.0, name: name, chooseBy: type)
        self.tNext = self.getDelay().0
    }
    
    override func outAct() {
        super.outAct()
        let (delay, item) = getDelay()
        self.tNext = tCurr + delay
        getNextElement()?.element.inAct(item)
    }
    
    func getDelay() -> (Double, T?) {
        guard delays.count > 0 else { return (Double.greatestFiniteMagnitude, nil) }
        
        if delays.reduce(0, { $0 + $1.probability }) != 1 {
            return (Double.greatestFiniteMagnitude, nil)
        }
        
        var sum = 0.0
        let randomValue = Double.random(in: 0...1)
        for delay in delays {
            sum += delay.probability
            if randomValue <= sum {
                switch delay.distribution {
                case .exponential:
                    return (FunRand.exponential(timeMean: delay.delayMean), delay.itemGenerator())
                case .normal:
                    return (FunRand.normal(
                        timeMean: delay.delayMean, timeDeviation: delay.delayDeviation),
                            delay.itemGenerator()
                    )
                case .uniform:
                    let timeMin = delay.delayMean - delay.delayDeviation
                    let timeMax = delay.delayMean + delay.delayDeviation
                    return (FunRand.uniform(timeMin: timeMin, timeMax: timeMax), delay.itemGenerator())
                case .erlang:
                    return (FunRand.erlang(timeMean: delay.delayMean, k: delay.k), delay.itemGenerator())
                }
            }
        }
        return (Double.greatestFiniteMagnitude, nil)
    }
}
