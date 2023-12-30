//
//  main.swift
//  System Modelling
//
//  Created by yasha on 03.11.2023.
//

import Foundation

class Client {
    static let distances: [Double: Int] = [0.1: 5, 0.2: 8, 0.25: 9, 0.17: 11, 0.23: 12, 0.05: 20]

    private(set) var attempts = 0
    var distance: Int = 9
    var tripDistance: Double = 0.0
    var orderedTaxiTime: Double = 0.0
    var endTripTime: Double = 0.0
    
    init() {
        var sum = 0.0
        let randomValue = Double.random(in: 0...1)
        for (probability, dist) in Client.distances {
            sum += probability
            if randomValue <= sum {
                self.distance = dist
            }
        }
    }
    
    func addAttempt() {
        attempts += 1
    }
}


var csvString = "Avarage call attempts,Finished trips,Failed trips,Avarage order time,Profit\n"

func testModel(withNumDrivers drivers: Int, totalWorkers workers: Int) throws -> (Double, Double) {
    guard 1...14 ~= drivers, 1...15 ~= workers else {
        throw "Drivers number should be between 1 and 14 and workers between 2 and 15"
    }
    
    let clients = Create(
        delays: [.init(delayMean: 180, probability: 1.0, .erlang, k: 2) { return Client() }],
        name: "Clients"
    )
    
    let typingTaxiNumber = Process<Client>(name: "Typing Taxi Number", channels: 1000, chooseBy: .byCondition) { client in
        return 30
    }
    typingTaxiNumber.outAction = { client, _ in
        client?.addAttempt()
    }
    
    let acceptingClients = Process<Client>(name: "Accepting clients", maxQueue: 0, channels: UInt(workers - drivers)) { _ in
        return 30
    }
    acceptingClients.outAction = { client, time in
        client?.orderedTaxiTime = time
    }
    
    let waitSixtySeconds = Process<Client>(name: "Wait 60 seconds", channels: 1000) { _ in
        return 60
    }
    let trip = Process<Client>(name: "Taxi Trip", channels: UInt(drivers)) { client in
        let carSpeed = FunRand.uniform(timeMin: 30, timeMax: 40)
        var timeInSeconds = 0.0
        if let client {
            timeInSeconds += (Double(client.distance) / carSpeed) * 60 * 60 // time to get to client
            let serviceTime = FunRand.uniform(timeMin: 30, timeMax: 50) * 60 // time to deliver client
            timeInSeconds += serviceTime
            let distance = carSpeed * (serviceTime / (60 * 60)) // distance travelled with client
            client.tripDistance = distance
        }
        return timeInSeconds
    }
    var profit = 0.0
    var totalClientsTripTime = 0.0
    var clientDelivered = 0
    var totalCallAttempts = 0
    trip.outAction = { client, time in
        guard let client else { return }
        client.endTripTime = time
        clientDelivered += 1
        totalClientsTripTime += client.endTripTime - client.orderedTaxiTime
        profit += 20 + client.tripDistance * 3
        totalCallAttempts += client.attempts
    }
    
    let failes = Process<Client>(name: "Failed Trip", channels: 1000) { _ in return 0 }
    failes.outAction = { client, _ in
        guard let client else { return }
        totalCallAttempts += client.attempts
    }
    
    clients.nextElements = [.init(element: typingTaxiNumber)]
    typingTaxiNumber.nextElements = [
        .init(element: acceptingClients, condition: { client in
            return trip.queue.count < 10 && acceptingClients.isFree()
        }),
        .init(element: failes, condition: { client in
            return (trip.queue.count >= 10 || !acceptingClients.isFree()) && client.attempts > 4
        }),
        .init(element: waitSixtySeconds, condition: { client in
            return (trip.queue.count >= 10 || !acceptingClients.isFree()) && client.attempts <= 4
        })
    ]
    waitSixtySeconds.nextElements = [.init(element: typingTaxiNumber)]
    acceptingClients.nextElements = [.init(element: trip)]
    
    
    let model = Model(elements: [clients, typingTaxiNumber, acceptingClients, waitSixtySeconds, trip, failes])
    model.simulate(forTime: 60 * 60 * 24)
//    print("Avarage call attempts: \(Double(totalCallAttempts) / Double(failes.quantity + trip.quantity))")
//    print("Failed trips: \(failes.quantity)")
//    print("Finished trips: \(trip.quantity)")
    csvString += "\(Double(totalCallAttempts) / Double(failes.quantity + trip.quantity)),"
        + "\(trip.quantity),\(failes.quantity),\(totalClientsTripTime / Double(clientDelivered)),"
        + "\(profit - Double(workers * 1000))\n"
    return (totalClientsTripTime / Double(clientDelivered), profit - Double(workers * 1000))
}

func writeToCsv(results: String, fileName: String) {
    let fileManager = FileManager.default
    
    do {
        let path = try fileManager.url(for: .downloadsDirectory, in: .allDomainsMask, appropriateFor: nil, create: true)
        let fileUrl = path.appendingPathComponent(fileName)
        
        try results.write(to: fileUrl, atomically: true, encoding: .utf8)
    } catch {}
}


func main() {
    do {
        var stats = [Int: [Int: (Double, Double)]]()
        let count = 20

        for workers in 1...15 {
            for drivers in 1..<workers {
                for _ in 1...count {
                    let modelStats = try testModel(withNumDrivers: drivers, totalWorkers: workers)
                    stats[workers - drivers, default: [:]][drivers, default: (0, 0)].0 += modelStats.0 / Double(count)
                    stats[workers - drivers, default: [:]][drivers, default: (0, 0)].1 += modelStats.1 / Double(count)
                }
            }
        }
        var csv = "Operators,Drivers,Order Time,Profit\n"
        for statsForWorkers in stats.sorted(by: { $0.key > $1.key }) {
            for drivers in statsForWorkers.value.sorted(by: { $0.key > $1.key }) {
                csv += "\(statsForWorkers.key),\(drivers.key),\(drivers.value.0),\(drivers.value.1)\n"
            }
        }
        writeToCsv(results: csv, fileName: "experiments.csv")
        
        var keysForBestOrderTime = (1, 1)
        var keysForBestProfit = (1, 1)
        let sorted = stats.sorted(by: { $0.key > $1.key })
        sorted.forEach { key, value in
            let sorted = value.sorted(by: { $0.key > $1.key })
            sorted.forEach {
                if $0.value.0 < stats[keysForBestOrderTime.0]![keysForBestOrderTime.1]!.0 {
                    keysForBestOrderTime = (key, $0.key)
                }
                if $0.value.1 > stats[keysForBestProfit.0]![keysForBestProfit.1]!.1 {
                    keysForBestProfit = (key, $0.key)
                }
                print("With \(key) operators and \($0.key) drivers: \($0.value.0)  \($0.value.1)")
            }
        }
        print("Best client process time was with \(keysForBestOrderTime.0) operators and \(keysForBestOrderTime.1) drivers")
        print("Highest profit was with \(keysForBestProfit.0) operators and \(keysForBestProfit.1) drivers")
    } catch {
        print(error)
    }
}

main()

extension String: Error {}
