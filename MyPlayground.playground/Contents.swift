import Foundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

//Это нужно просто для подсчета и для принтов
var numberOfChipsAdded = 0
var numberOfChipsRemoved = 0
var numberOfSolderedChips = 0

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }

    public let chipType: ChipType

    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }

        return Chip(chipType: chipType)
    }

    public func sodering() {
        let soderingTime = chipType.rawValue
        sleep(UInt32(soderingTime))
        numberOfSolderedChips += 1
        print("Количество припаянных чипов - \(numberOfSolderedChips)")
    }
}

class Storage {
    private let condition = NSCondition()
    var storageForChip: [Chip] = []
    var availables = false

    func push(item: Chip) {
        condition.lock()
        storageForChip.append(item)

        numberOfChipsAdded += 1
        print("\nКол-во созданных чипов - \(numberOfChipsAdded)")

        availables = true
        condition.signal()
        condition.unlock()
    }

    func pop() -> Chip {
        condition.lock()

        while (!availables) {
            print("Жду Сигнал")
            condition.wait()
        }
        
        print("Получил сигнал")
        availables = false
        condition.unlock()

        return storageForChip.removeLast()
    }
}

class GeneratingThread: Thread {
    private let storage: Storage
    private var timer = Timer()
    private let timerIteration: TimeInterval
    let generationTime: TimeInterval

    init(storage: Storage, timerIteration: TimeInterval, generationTime: TimeInterval) {
        self.storage = storage
        self.timerIteration = timerIteration
        self.generationTime = generationTime
    }

    override func main() {
        timer = Timer.scheduledTimer(timeInterval: timerIteration,
                                     target: self,
                                     selector: #selector(getChip),
                                     userInfo: nil, repeats: true)

        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: generationTime))
    }

    @objc private func getChip() {
        storage.push(item: Chip.make())
    }
}

class WorkThread: Thread {
    private let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    override func main() {
        repeat {
            storage.pop().sodering()
            numberOfChipsRemoved += 1
            print("Кол-во удаленных чипов из массива - \(numberOfChipsRemoved)")
            
        } while storage.storageForChip.isEmpty || storage.availables
    }
}
  

let storage = Storage()
let generatingThread = GeneratingThread(storage: storage, timerIteration: 2, generationTime: 20)
let workThread = WorkThread(storage: storage)

workThread.start()
generatingThread.start()

sleep(UInt32(generatingThread.generationTime))
generatingThread.cancel()
workThread.cancel()


