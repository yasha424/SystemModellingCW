//
//  NextElement.swift
//  System Modelling
//
//  Created by yasha on 11.11.2023.
//

enum NextElementError: Error {
    case undefinedPriority
    case undefinedProbability
    case probabilitySumNotEqualToOne
}

class NextElement<T> {
    typealias ConditionFunc = ((_ item: T) -> Bool)?
    typealias ItemGenerator = () -> T?
    
    let element: Element<T>
    let priority: Int?
    let probability: Double?
    let condition: ConditionFunc
    let itemGenerator: ItemGenerator?
    
    init(element: Element<T>, priority: Int? = nil, probability: Double? = nil, condition: ConditionFunc = nil, itemGenerator: ItemGenerator? = nil) {
        self.element = element
        self.priority = priority
        self.probability = probability
        self.condition = condition
        self.itemGenerator = itemGenerator
    }
}
