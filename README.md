# giphy

# 디자인 패턴
뷰는 오로지 화면을 렌더링하는 역활을 하고 비즈니스 로직을 한 곳에서 처리하도록 리덕스 패턴을 사용했습니다.
- Action

뷰에서 이벤트가 발생할 때 전달되는 객체입니다.
``` Swift
    enum Action: Equatable {
        case searchBarChanged(String)
        case searchButtonTapped
        case replaceItems(UIImage?)
    }

```

<br>

- State

View를 꾸미는 상태와 Store에서 사용하는 상태를 뜻합니다. <br>
View.State와 Store.State는 같거나 다를 수 있습니다.
``` Swift
    // MARK: - store가 관리하는 state
    struct State: Equatable {
        static var empty = Self(query: "", items: [])
        var query: String
        var items: [UIImage?]
    }

    // MARK: - view가 관리하는 state
    private func update(with state: [UIImage?]) {
        ...
    }

```

<br>

- Environment

dependency container입니다.  <br>
redcuer 내부에서 복잡한 로직을 제거하고, 테스트 가능하게 만들어주는 객체입니다.(제어권을 갖고오도록 도와주는 객체)

``` Swift
    struct Environment {
        let scheduler: DispatchQueue
        let search: (String) -> AnyPublisher<UIImage?, Never>
    }
```

<br>

- Reducer


action과 state를 사용해서 새로운 state를 만들거나 effect를 발생시키는 역할을 합니다. <br>
effect란 reducer내부에 state를 변경하지 않는 경우를 말합니다. (ex. 비동기적으로 데이터르 받는 상황, 화면 전환) <br>
state는 구조체이기 때문에 클로저 내부에서 값을 변경하 수 없습니다. 이 문제를 해결하기위해 새로운 Action을 방출하도록 구현합니다.

``` Swift
        func reduce(
            _ action: SearchListViewController.Action,
            state: inout State
        ) -> AnyPublisher<SearchListViewController.Action, Never>? {
            switch action {
            // MARK: - effect가 발생합니다.
            case .searchButtonTapped:
                state.items = []
                return environment.search(state.query)
                    .map { SearchListViewController.Action.replaceItems($0) }
                    .eraseToAnyPublisher()
                    
            // MARK: - effect가 발생하지 않습니다.
            case let .replaceItems(items):
                state.items.append(items)
            }
            
            return nil
        }

```

<br>

- Store

위 네가지를 보유하며, viwe와 직접적으로 통신하는 객체입니다.. <br>

``` Swift
final class SearchListViewStore {
    private var reducer: Reducer 
    let actionListener: PassthroughSubject<SearchListViewController.Action, Never>     // MARK: - view를 통해서  action을 받는 객체
    @Published private var state: State
    private let environment: Environment
}


``` 

<br>
<br>
<br>

# 고민한 점
- 비동기방식으로 UI 업데이트 (스트림 분리)

URL -> Data -> UIImage 일련 변경하는 과정을 동기적으로 처리하게 되면, UI가 멈춰있는 현상을 발견했습니다. <br>
아래 사진처럼 URL 배열을 서버로 부터 받게 되면, URL -> Data -> UIImage 작업을 비동기적으로 처리해서 최종적으론 UIImage를 뷰에 비동기적으로 반영되도록 구현했습니다.<br>
스트림을 분리하면서 SearchListViewController에 있는 비즈니스 로직 전부를 제거할 수 있었습니다.
<img width="1031" alt="Screen Shot 2021-09-20 at 17 45 02" src="https://user-images.githubusercontent.com/48466830/133976636-3e0270ef-bc8e-4d1d-826c-a12c3b02bc27.png"> 

수정한 코드
``` Swift
    func fetchItems(query: String) -> AnyPublisher<UIImage?, Never> {
        guard let url = makeURL(query) else {
            return Just(nil)
                .eraseToAnyPublisher()
        }
        
        return urlSession.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GIPHYData.self, decoder: decoder)
            .map(\.urls)
            .flatMap { items in
                items.publisher
                    .flatMap { item -> AnyPublisher<UIImage?, Never> in
                        let subject = PassthroughSubject<UIImage?, Never>()
                        // MARK: - 비동기적으로 데이터 전달
                        DispatchQueue.global().async { [weak subject] in
                            guard let data = try? Data(contentsOf: item) else { return }
                            let image = UIImage(data: data)
                            subject?.send(image)
                            subject?.send(completion: .finished)
                        }
                        
                        return subject
                            .eraseToAnyPublisher()
                    }
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

```

<br>
<br>

- fire and forget effect <br>

Server API를 호출할 때마다 Effect가 저장되고 지워지지 않는 심각한 버그를 발견했습니다.(스트림을 분리하면서 발생한 side effect입니다.) <br>
디버깅 결과 Effect가 발생할때마다 저장되는 걸 확인 후 Effect를 사용하고 제거하도록 수정했습니다.
<img width="490" alt="Screen Shot 2021-09-20 at 23 09 47" src="https://user-images.githubusercontent.com/48466830/134016956-ff0cbd33-5ab1-4860-a0de-52a5344e81cd.png">

수정한 코드
``` Swift
    private func fireEffectAndForget(_ effect: AnyPublisher<SearchListViewController.Action, Never>) {
        var cancellable: AnyCancellable?
        cancellable = effect
            .sink(receiveCompletion: { result in
                guard case .finished = result,
                      let cancellable = cancellable else { return }
                /// MARK: - forget effect
                self.cancellables.remove(cancellable)
            }, receiveValue: { action in
                /// MARK: - fire effect
                self.reducer.reduce(action, state: &self.state)
            })
        cancellable?
            .store(in: &cancellables)
    }
```

<br>
<br>
<br>

# 화면 구성
### 설계

<br>


<img width="700" alt="Screen Shot 2021-09-20 at 17 21 10" src="https://user-images.githubusercontent.com/48466830/133974854-33efc703-b927-45f0-8e56-0e3dc41daf57.png">

<br>
<br>

### 구현 화면
<img width="400" alt="Screen Shot - iPhone 12 mini - 2021-09-20" src="https://user-images.githubusercontent.com/48466830/133974995-03a1ad3a-c22d-4f32-ab6c-a79172593165.png">
