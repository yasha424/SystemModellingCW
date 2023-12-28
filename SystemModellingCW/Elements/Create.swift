//
//  Create.swift
//  System Modelling
//
//  Created by yasha on 03.11.2023.
//

struct CreatorDelay<T> {
    let delayMean: Double
    let probability: Double
    let itemGenerator: () -> T?
    
    init(delayMean: Double, probability: Double, _ itemGenerator: @escaping () -> T? = { return nil }) {
        self.delayMean = delayMean
        self.probability = probability
        self.itemGenerator = itemGenerator
    }
}

class Create<T>: Element<T> {
    
    private let delays: [CreatorDelay<T>]
    
    init(delays: [CreatorDelay<T>], name: String, chooseBy type: NextElementsChooseType) {
        self.delays = delays
        super.init(delay: 1.0, name: name, chooseBy: type)
        self.tNext = 0
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
                return (FunRand.exponential(timeMean: delay.delayMean), delay.itemGenerator())
            }
        }
        return (Double.greatestFiniteMagnitude, nil)
    }
}
