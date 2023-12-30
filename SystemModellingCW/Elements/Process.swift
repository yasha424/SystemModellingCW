//
//  Process.swift
//  System Modelling
//
//  Created by yasha on 03.11.2023.
//

class Process<T>: Element<T> {
    var queue: [T?] = []
    private(set) var maxQueue: Int = 0
    private(set) var failure: Int = 0
    private(set) var meanQueue: Double = 0
    private(set) var channelsStates = [Int]()
    private(set) var channelsTNext = [Double]()
    private(set) var channelsItems = [T?]()
    private(set) var totalLoadTime: Double = 0
    var outAction: ((_ item: T?, _ currentTime: Double) -> Void)? = nil
    var getDelay: (_ item: T?) -> Double
    
    init(name: String = "", maxQueue: Int = Int.max, channels: UInt = 1, chooseBy type: NextElementsChooseType = .priority, delay: @escaping (_ item: T?) -> Double) {
        self.maxQueue = maxQueue
        self.getDelay = delay
        
        channelsStates = Array(repeating: 0, count: Int(channels))
        channelsTNext = Array(repeating: Double.greatestFiniteMagnitude, count: Int(channels))
        channelsItems = Array(repeating: nil, count: Int(channels))

        super.init(delay: 1, name: name, chooseBy: type)
    }
        
    override func inAct(_ item: T? = nil) {
        let delay = getDelay(item)

        if !channelsStates.isEmpty {
            if let availableChannel = channelsStates.firstIndex(where: { $0 == 0 }) {
                channelsStates[availableChannel] = 1
                channelsTNext[availableChannel] = tCurr + delay
                channelsItems[availableChannel] = item
                totalLoadTime += delay
                tNext = channelsTNext.min() ?? Double.greatestFiniteMagnitude
            } else {
                if queue.count < maxQueue {
                    queue.append(item)
                } else {
                    failure += 1
                }
            }
        }
    }
    
    override func outAct() {
        super.outAct()
        
        var currItem: T? = nil
        if !channelsStates.isEmpty {
            if let currChannel = channelsTNext.firstIndex(where: { $0 == tCurr }) {
                channelsStates[currChannel] = 0
                channelsTNext[currChannel] = Double.greatestFiniteMagnitude
                currItem = channelsItems[currChannel]
                let delay = getDelay(currItem)
                if let outAction {
                    outAction(currItem, tCurr)
                }
                channelsItems[currChannel] = nil
                if queue.count > 0 {
                    channelsStates[currChannel] = 1
                    channelsTNext[currChannel] = tCurr + delay
                    channelsItems[currChannel] = queue.removeFirst()
                    totalLoadTime += delay
                }
                tNext = channelsTNext.min() ?? Double.greatestFiniteMagnitude
            }
        } 
        if let nextElement = getNextElement(currItem) {
            nextElement.element.inAct(nextElement.itemGenerator == nil ? currItem : nextElement.itemGenerator?())
        }
    }
    
    override func printInfo() {
        super.printInfo()
        print("queue length = \(queue.count), failure = \(failure)")
    }
    
    override func doStatistics(delta: Double) {
        meanQueue += Double(queue.count) * delta
    }
    
    override func isFree() -> Bool {
        if !channelsStates.isEmpty {
            return channelsStates.contains(0) || queue.count < maxQueue ? true : false
        } else {
            return state == 0
        }
    }
    
    func getFailureProbability() -> Double {
        guard self.quantity != 0 else { return 0 }
        return Double(self.failure) / Double(self.quantity + self.failure)
    }
}
